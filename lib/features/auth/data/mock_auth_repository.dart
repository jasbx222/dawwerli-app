import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';

/// In-memory mock. Valid code: 481923. 5 wrong codes → 15-minute lock.
/// Channel rule: switch to WhatsApp only after 3 FAILED SMS deliveries (not 3 total sends).
/// NOTE: the backend (POST /v1/auth/otp/request) must apply the same rule, counting failures from
/// SMS provider delivery reports plus "not received" resends.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    DateTime Function()? clock,
    this.simulateSmsFailure = false,
  }) : _now = clock ?? DateTime.now;

  static const maxFailedSms = 3;

  /// When true every SMS is reported undelivered by the (fake) provider.
  final bool simulateSmsFailure;

  static const validCode = '481923';
  static const maxWrong = 5;
  static const lockFor = Duration(minutes: 15);
  static const codeTtl = Duration(minutes: 5);

  final DateTime Function() _now;
  final _wrong = <String, int>{};
  final _failedSms = <String, int>{};
  final _lastChannel = <String, OtpChannel>{};
  final _issuedAt = <String, DateTime>{};
  final _lockedUntil = <String, DateTime>{};

  Duration? _lockLeft(String k) {
    final until = _lockedUntil[k];
    if (until == null) return null;
    final left = until.difference(_now());
    return left.isNegative ? null : left;
  }

  @override
  Future<OtpRequestResult> requestOtp(
    PhoneNumber phone, {
    bool smsNotReceived = false,
  }) async {
    final k = phone.e164;
    final locked = _lockLeft(k);
    if (locked != null) return OtpLocked(locked);
    if (smsNotReceived && _lastChannel[k] == OtpChannel.sms) {
      _failedSms[k] = (_failedSms[k] ?? 0) + 1;
    }
    final channel = (_failedSms[k] ?? 0) >= maxFailedSms
        ? OtpChannel.whatsapp
        : OtpChannel.sms;
    if (channel == OtpChannel.sms && simulateSmsFailure) {
      _failedSms[k] = (_failedSms[k] ?? 0) + 1;
    }
    _lastChannel[k] = channel;
    _issuedAt[k] = _now();
    return OtpSent(
      channel: channel,
      expiresIn: codeTtl,
      resendIn: const Duration(seconds: 60),
    );
  }

  @override
  Future<OtpVerifyResult> verifyOtp(PhoneNumber phone, String code) async {
    final k = phone.e164;
    final locked = _lockLeft(k);
    if (locked != null) return OtpVerifyLocked(locked);
    final issued = _issuedAt[k];
    if (issued != null && _now().difference(issued) > codeTtl) {
      return const OtpExpired();
    }
    if (code == validCode) {
      _wrong.remove(k);
      return const OtpOk(needsProfile: true);
    }
    final w = (_wrong[k] ?? 0) + 1;
    _wrong[k] = w;
    if (w >= maxWrong) {
      _wrong.remove(k);
      _lockedUntil[k] = _now().add(lockFor);
      return const OtpVerifyLocked(lockFor);
    }
    return OtpWrong(maxWrong - w);
  }

  @override
  Future<List<String>> governorates() async => const [
    'بغداد',
    'البصرة',
    'نينوى',
    'أربيل',
    'النجف',
    'كربلاء',
    'بابل',
    'ديالى',
    'الأنبار', //
    'ذي قار',
    'السليمانية',
    'كركوك',
    'صلاح الدين',
    'واسط',
    'ميسان',
    'المثنى',
    'القادسية',
    'دهوك',
  ];

  @override
  Future<void> saveProfile({
    required String name,
    required String governorate,
    required String area,
  }) async =>
      _profile = UserProfile(name: name, governorate: governorate, area: area);

  /// Mock seed: a signed-in Baghdad user until 05 saves a real profile.
  UserProfile? _profile = const UserProfile(
    name: 'أبو علي',
    governorate: 'بغداد',
    area: 'الكرادة',
  );

  @override
  Future<UserProfile?> profile() async => _profile;
}
