import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Line icons copied from the approved designs (24×24 viewBox, stroke 2).
enum AppIcon {
  back('<path d="m9 18 6-6-6-6"/>'),
  whatsapp(
    '<path d="M3 21l1.6-5A9 9 0 1 1 8 19.4z"/><path d="M9 9.5c.5 2 2.5 4 4.5 4.5l1-1.2 2 .9c-.3 1.3-1.3 1.8-2.3 1.8C10 15.5 8.5 14 8 10.8c0-1 .6-2 1.8-2.3l.9 2z"/>',
  ),
  lock(
    '<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  ),
  lockDot(
    '<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/><circle cx="12" cy="16" r="1.2"/>',
  ),
  clock('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
  xCircle('<circle cx="12" cy="12" r="9"/><path d="m15 9-6 6M9 9l6 6"/>'),
  hourglass(
    '<path d="M6 2h12M6 22h12M7 2c0 5 10 5 10 10S7 17 7 22M17 2c0 5-10 5-10 10s10 5 10 10"/>',
  ),
  pin(
    '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  ),
  bell(
    '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  ),
  home(
    '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
  ),
  clipboard(
    '<rect x="8" y="2" width="8" height="4" rx="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="M9 12h6M9 16h4"/>',
  ),
  user(
    '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  ),
  plus('<path d="M12 5v14M5 12h14"/>'),
  chevronLeft('<path d="m15 18-6-6 6-6"/>'),
  verified('<circle cx="12" cy="12" r="9"/><path d="m9 12 2 2 4-4"/>'),
  check('<path d="M5 12.5l4.5 4.5L19 7"/>'),
  camera(
    '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/>',
  ),
  text('<path d="M4 7V4h16v3M9 20h6M12 4v16"/>'),
  mic(
    '<rect x="9" y="2" width="6" height="12" rx="3"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><path d="M12 19v3"/>',
  ),
  shield(
    '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>',
  ),
  wifiOff(
    '<path d="M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M5 12.9a10 10 0 0 1 5.2-2.8M19 12.9a10 10 0 0 0-2-1.5M2 8.8a15 15 0 0 1 4.2-2.7M22 8.8A15 15 0 0 0 11 5"/><circle cx="12" cy="20" r="1"/>',
  ),
  barChart(
    '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
  ),
  filter('<path d="M22 3H2l8 9.46V19l4 2v-8.54z"/>'),
  flag(
    '<path d="M4 22V4s1-1 4-1 5 2 8 2 4-1 4-1v12s-1 1-4 1-5-2-8-2-4 1-4 1"/>',
  ),
  zap('<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/>'),
  flame(
    '<path d="M12 22a7 7 0 0 0 7-7c0-4-3-6-4-10-2 2-3 4-3 6-1-1-2-2-2-4-2 2-5 5-5 8a7 7 0 0 0 7 7z"/>',
  ),
  moon('<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>'),
  alert(
    '<path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
  ),
  sparkles(
    '<path d="M12 3l1.9 5.8L20 10l-6.1 1.2L12 17l-1.9-5.8L4 10l6.1-1.2z"/><path d="M19 17l.7 2.3L22 20l-2.3.7L19 23l-.7-2.3L16 20l2.3-.7z"/>',
  ),
  shieldCheck(
    '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>',
  ),
  chat(
    '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
  ),
  refresh('<path d="M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5"/>'),
  trash('<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/>'),
  trophy(
    '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0z"/><path d="M17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3"/>',
  ),
  smile(
    '<circle cx="12" cy="12" r="9"/><path d="M8 15s1.5 2 4 2 4-2 4-2M9 9.5h.01M15 9.5h.01"/>',
  ),
  sparkle('<path d="M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2zM19 3v4M17 5h4"/>'),
  wifiOffSmall(
    '<path d="M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M5 12.9a10 10 0 0 1 5.2-2.8M2 8.8a15 15 0 0 1 4.2-2.7"/><circle cx="12" cy="20" r="1"/>',
  ),
  snowflake('<path d="M12 2v20M3.5 7l17 10M20.5 7l-17 10"/>'),
  x('<path d="M6 6l12 12M18 6 6 18"/>'),
  star(
    '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-5.18 3.25L8 14.14 3 9.27l6.91-1.01z"/>',
    filled: true,
  );

  const AppIcon(this.body, {this.filled = false});
  final String body;
  final bool filled;
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.icon, {
    super.key,
    required this.color,
    this.size = 24,
    this.strokeWidth = 2,
  });

  final AppIcon icon;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      icon.filled
          ? '<svg width="24" height="24" viewBox="0 0 24 24" fill="$hex">${icon.body}</svg>'
          : '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="$strokeWidth" '
                'stroke-linecap="round" stroke-linejoin="round">${icon.body}</svg>',
      width: size,
      height: size,
    );
  }
}
