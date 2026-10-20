/// 35000 → "35,000"
String thousands(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// Duration → "23:41" (hours:minutes)
String hhmm(Duration d) => '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
