import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Line icons copied from the approved designs (24×24 viewBox, stroke 2).
enum AppIcon {
  back('<path d="m9 18 6-6-6-6"/>'),
  whatsapp(
      '<path d="M3 21l1.6-5A9 9 0 1 1 8 19.4z"/><path d="M9 9.5c.5 2 2.5 4 4.5 4.5l1-1.2 2 .9c-.3 1.3-1.3 1.8-2.3 1.8C10 15.5 8.5 14 8 10.8c0-1 .6-2 1.8-2.3l.9 2z"/>'),
  lock('<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>'),
  lockDot('<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/><circle cx="12" cy="16" r="1.2"/>'),
  clock('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
  xCircle('<circle cx="12" cy="12" r="9"/><path d="m15 9-6 6M9 9l6 6"/>'),
  hourglass('<path d="M6 2h12M6 22h12M7 2c0 5 10 5 10 10S7 17 7 22M17 2c0 5-10 5-10 10s10 5 10 10"/>'),
  pin('<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>');

  const AppIcon(this.body);
  final String body;
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(this.icon, {super.key, required this.color, this.size = 24});

  final AppIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round">${icon.body}</svg>',
      width: size,
      height: size,
    );
  }
}
