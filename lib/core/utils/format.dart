/// 35000 → "35,000"
String thousands(int v) =>
    v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// Duration → "23:41" (hours:minutes)
String hhmm(Duration d) =>
    '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';

/// Relative Arabic time for lists: «هسه», «قبل 8 د», «قبل 3 س», «أمس», then «20/10».
String agoLabel(DateTime at, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(at);
  if (d.inMinutes < 1) return 'هسه';
  if (d.inHours < 1) return 'قبل ${d.inMinutes} د';
  if (d.inDays < 1) return 'قبل ${d.inHours} س';
  if (d.inDays == 1) return 'أمس';
  return dayMonth(at);
}

/// 2026-10-20 → "20/10"
String dayMonth(DateTime at) => '${at.day}/${at.month}';

/// 2026-10-21 21:42 → "21/10 · 9:42 م"
String dayTimeLabel(DateTime at) {
  const noon = 12;
  final h = at.hour % noon == 0 ? noon : at.hour % noon;
  final suffix = at.hour < noon ? 'ص' : 'م';
  return '${dayMonth(at)} · $h:${at.minute.toString().padLeft(2, '0')} $suffix';
}
