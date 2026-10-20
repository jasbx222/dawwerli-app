import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../../core/api/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';

/// OTP login against `/api/v1/auth/*`; tokens go to [TokenStore].
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.api, this.tokens, this.catalog, this.role, this.onDevCode);

  final ApiClient api;
  final TokenStore tokens;
  final Future<Catalog> Function() catalog;

  /// 'customer' or 'page', from the «أشتري/أبيع» choice.
  final String Function() role;

  /// Development builds of the API echo the code (no SMS gateway yet).
  final void Function(String?) onDevCode;

  @override
  Future<OtpRequestResult> requestOtp(PhoneNumber phone, {bool smsNotReceived = false}) async {
    try {
      final r = await api.post<Map<String, dynamic>>('/api/v1/auth/otp/request', {
        'phone': phone.e164,
        'smsNotReceived': smsNotReceived,
      });
      onDevCode(r.os('devCode'));
      return OtpSent(
        channel: r.s('channel') == 'whatsApp' ? OtpChannel.whatsapp : OtpChannel.sms,
        expiresIn: Duration(seconds: r.i('expiresIn')),
        resendIn: Duration(seconds: r.i('resendIn')),
      );
    } on ApiException catch (e) {
      final wait = Duration(seconds: e.retryIn ?? 0);
      if (e.code == 'otp.locked') return OtpLocked(wait);
      if (e.status == 429) return OtpRateLimited(wait);
      rethrow;
    }
  }

  @override
  Future<OtpVerifyResult> verifyOtp(PhoneNumber phone, String code) async {
    try {
      final r = await api.post<Map<String, dynamic>>('/api/v1/auth/otp/verify', {
        'phone': phone.e164,
        'code': code,
        'role': role(),
        'deviceId': await tokens.device(newId),
      });
      await tokens.save(r.s('accessToken'), r.s('refreshToken'));
      onDevCode(null);
      return OtpOk(needsProfile: r.b('needsProfile'));
    } on ApiException catch (e) {
      return switch (e.code) {
        'otp.wrong' => OtpWrong((e.data['attemptsLeft'] as num?)?.toInt() ?? 0),
        'otp.locked' => OtpVerifyLocked(Duration(seconds: e.retryIn ?? 0)),
        'otp.expired' => const OtpExpired(),
        _ => throw e,
      };
    }
  }

  @override
  Future<List<String>> governorates() async => [for (final g in (await catalog()).governorates) g.name];

  @override
  Future<void> saveProfile({required String name, required String governorate, required String area}) async {
    final id = (await catalog()).governorateId(governorate);
    await api.put<void>('/api/v1/me/profile', {'name': name, 'governorateId': id, 'area': area});
  }

  /// Re-issues tokens for the other side of the app (buyer ⇄ seller), same phone account.
  Future<void> switchRole(String newRole) async {
    if (!tokens.signedIn) return;
    final r = await api.post<Map<String, dynamic>>('/api/v1/auth/switch-role', {
      'role': newRole,
      'deviceId': await tokens.device(newId),
    });
    await tokens.save(r.s('accessToken'), r.s('refreshToken'));
  }

  Future<void> logout() async {
    final r = tokens.refresh;
    if (r != null) {
      try {
        await api.post<void>('/api/v1/auth/logout', {'refreshToken': r});
      } on ApiException {
        // Signing out locally is enough.
      }
    }
    await tokens.clear();
  }
}

/// Last OTP echoed by a development API (shown on the OTP screen).
class DevOtpCode extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? v) => state = v;
}

final devOtpCodeProvider = NotifierProvider<DevOtpCode, String?>(DevOtpCode.new);
