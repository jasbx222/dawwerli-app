import 'phone_number.dart';

enum OtpChannel { sms, whatsapp }

sealed class OtpRequestResult {
  const OtpRequestResult();
}

class OtpSent extends OtpRequestResult {
  const OtpSent({
    required this.channel,
    required this.expiresIn,
    required this.resendIn,
  });
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

/// Phone + password sign-in (POST /v1/auth/login) and OTP reset results.
sealed class PasswordLoginResult {
  const PasswordLoginResult();
}

class LoginOk extends PasswordLoginResult {
  const LoginOk({required this.needsProfile});
  final bool needsProfile;
}

class LoginWrong extends PasswordLoginResult {
  const LoginWrong();
}

class LoginLocked extends PasswordLoginResult {
  const LoginLocked(this.retryIn);
  final Duration retryIn;
}

/// Reset rejected because the OTP was wrong or expired.
class LoginCodeInvalid extends PasswordLoginResult {
  const LoginCodeInvalid();
}

/// Why the server refused a new password.
enum PasswordError { tooShort, mismatch }

/// Contract mirrors POST /v1/auth/otp/request, /v1/auth/otp/verify, PUT /v1/me (API comes later).
abstract interface class AuthRepository {
  /// [smsNotReceived] = the user is resending because the previous SMS never arrived
  /// (counts as a failed delivery, alongside provider delivery-failure reports).
  Future<OtpRequestResult> requestOtp(
    PhoneNumber phone, {
    bool smsNotReceived = false,
  });
  Future<OtpVerifyResult> verifyOtp(PhoneNumber phone, String code);
  Future<PasswordLoginResult> login(PhoneNumber phone, String password);

  /// Signed-in user (right after OTP sign-up) sets a password.
  Future<PasswordError?> setPassword(String password);

  /// Forgot password: [code] comes from [requestOtp] for the same phone.
  Future<PasswordLoginResult> resetPassword(
    PhoneNumber phone,
    String code,
    String password,
  );
  Future<List<String>> governorates();
  Future<void> saveProfile({
    required String name,
    required String governorate,
    required String area,
  });
}
