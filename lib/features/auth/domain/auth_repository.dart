import 'phone_number.dart';

enum OtpChannel { sms, whatsapp }

sealed class OtpRequestResult {
  const OtpRequestResult();
}

class OtpSent extends OtpRequestResult {
  const OtpSent({required this.channel, required this.expiresIn, required this.resendIn});
  final OtpChannel channel;
  final Duration expiresIn;
  final Duration resendIn;
}

class OtpRateLimited extends OtpRequestResult {
  const OtpRateLimited(this.retryIn);
  final Duration retryIn;
}

class OtpLocked extends OtpRequestResult {
  const OtpLocked(this.retryIn);
  final Duration retryIn;
}

sealed class OtpVerifyResult {
  const OtpVerifyResult();
}

class OtpOk extends OtpVerifyResult {
  const OtpOk({required this.needsProfile});
  final bool needsProfile;
}

class OtpWrong extends OtpVerifyResult {
  const OtpWrong(this.attemptsLeft);
  final int attemptsLeft;
}

class OtpExpired extends OtpVerifyResult {
  const OtpExpired();
}

class OtpVerifyLocked extends OtpVerifyResult {
  const OtpVerifyLocked(this.retryIn);
  final Duration retryIn;
}

/// Contract mirrors POST /v1/auth/otp/request, /v1/auth/otp/verify, PUT /v1/me (API comes later).
abstract interface class AuthRepository {
  Future<OtpRequestResult> requestOtp(PhoneNumber phone);
  Future<OtpVerifyResult> verifyOtp(PhoneNumber phone, String code);
  Future<List<String>> governorates();
  Future<void> saveProfile({required String name, required String governorate, required String area});
}
