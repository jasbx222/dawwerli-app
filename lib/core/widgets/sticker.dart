import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

const _deg7 = -7 * 3.141592653589793 / 180;

/// `.stk`: coral sticker rotated −7°.
class Sticker extends StatelessWidget {
  const Sticker(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: _deg7,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sticker,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xB3FF7A59),
            offset: Offset(0, 4),
            blurRadius: 10,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: AppText.lh(12),
          fontWeight: FontWeight.w700,
          color: AppColors.stickerText,
        ),
      ),
    ),
  );
}
