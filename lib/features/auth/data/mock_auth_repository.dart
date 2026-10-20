import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';

/// In-memory mock. Valid code: 481923. 5 wrong codes → 15-minute lock.
/// After 3 SMS sends the 4th goes over WhatsApp.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const validCode = '481923';
  static const maxWrong = 5;
  static const lockFor = Duration(minutes: 15);
  static const codeTtl = Duration(minutes: 5);

  final DateTime Function() _now;
  final _wrong = <String, int>{};
  final _sends = <String, int>{};
  final _issuedAt = <String, DateTime>{};
  final _lockedUntil = <String, DateTime>{};

  Duration? _lockLeft(String k) {
    final until = _lockedUntil[k];
    if (until == null) return null;
    final left = until.difference(_now());
    return left.isNegative ? null : left;
  }

  @override
  Future<OtpRequestResult> requestOtp(PhoneNumber phone) async {
    final k = phone.e164;
    final locked = _lockLeft(k);
    if (locked != null) return OtpLocked(locked);
    final n = (_sends[k] ?? 0) + 1;
    _sends[k] = n;
    _issuedAt[k] = _now();
    return OtpSent(
      channel: n > 3 ? OtpChannel.whatsapp : OtpChannel.sms,
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
    if (issued != null && _now().difference(issued) > codeTtl) return const OtpExpired();
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
        'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كربلاء', 'بابل', 'ديالى', 'الأنبار', //
        'ذي قار', 'السليمانية', 'كركوك', 'صلاح الدين', 'واسط', 'ميسان', 'المثنى', 'القادسية', 'دهوك',
      ];

  @override
  Future<void> saveProfile({required String name, required String governorate, required String area}) async {}
}
