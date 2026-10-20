import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';

/// Navy snackbar-style banner (09b offline): pad 13/14, radius 18, 13.5px semibold.
class ToastBar extends StatelessWidget {
  const ToastBar(
    this.text, {
    super.key,
    this.icon = AppIcon.wifiOff,
    this.iconColor = AppColors.white,
  });
  final String text;
  final AppIcon icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 14),
          blurRadius: 30,
          spreadRadius: -10,
        ),
      ],
    ),
    child: Row(
      children: [
        AppSvgIcon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: AppText.lh(13.5),
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Offline / notice toast (31) — same bar.
typedef OfflineBanner = ToastBar;
