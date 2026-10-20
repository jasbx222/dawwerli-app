import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_store.dart';

/// Account deletion: a code goes to my phone, then POST /me/delete with it.
class AccountApi {
  const AccountApi(this.api, this.tokens);
  final ApiClient api;
  final TokenStore tokens;

  /// Returns the dev echo code when the API runs in Development (null in production).
  Future<String?> requestDeleteCode() async =>
      (await api.post<Map<String, dynamic>>('/api/v1/me/delete-code')).os('devCode');

  Future<void> delete(String code) async {
    await api.post<void>('/api/v1/me/delete', {'code': code});
    await tokens.clear();
  }
}

final accountApiProvider = Provider<AccountApi>(
  (ref) => AccountApi(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)),
);

/// GET /api/v1/me — name, region and phone of the signed-in account.
class Me {
  const Me({required this.name, required this.phone});
  final String name;
  final String phone;

  /// «+964 770 ••• 4567»: only the operator prefix and last 4 digits shown.
  String get maskedPhone {
    const visibleTail = 4, prefix = 7;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= prefix + visibleTail) return phone;
    return '+${digits.substring(0, 3)} ${digits.substring(3, 6)} ••• ${digits.substring(digits.length - visibleTail)}';
  }

  String get initial => name.isEmpty ? '' : name.characters.first;
}

final meProvider = FutureProvider.autoDispose<Me>((ref) async {
  final j = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/api/v1/me');
  return Me(name: j.os('name') ?? '', phone: j.s('phone'));
});
