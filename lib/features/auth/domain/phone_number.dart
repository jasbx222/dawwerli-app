enum PhoneError { incomplete, notIraqi }

/// Iraqi mobile: 10 digits starting with 7 after +964 (or 0 / 00964 prefixes).
class PhoneNumber {
  const PhoneNumber._(this.national);

  /// 10-digit national number, e.g. 7701234567.
  final String national;

  String get e164 => '+964$national';

  /// "770 123 4567"
  String get pretty => '${national.substring(0, 3)} ${national.substring(3, 6)} ${national.substring(6)}';

  static ({PhoneNumber? phone, PhoneError? error}) parse(String raw) {
    var s = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    s = s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    if (s.startsWith('+')) {
      if (!s.startsWith('+964')) return (phone: null, error: PhoneError.notIraqi);
      s = s.substring(4);
    }
    if (s.startsWith('0')) s = s.substring(1);
    if (s.isNotEmpty && !s.startsWith('7')) return (phone: null, error: PhoneError.notIraqi);
    if (s.length < 10 || !RegExp(r'^\d+$').hasMatch(s)) return (phone: null, error: PhoneError.incomplete);
    if (s.length > 10) return (phone: null, error: PhoneError.notIraqi);
    return (phone: PhoneNumber._(s), error: null);
  }
}
