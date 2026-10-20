import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.inp` row with a radio on the far side; selected = `.inp.f`.
class RadioRow extends StatelessWidget {
  const RadioRow({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on ? AppColors.blue : AppColors.border,
          width: 1.5,
        ),
        boxShadow: on
            ? const [BoxShadow(color: Color(0x1F1F4E9C), spreadRadius: 4)]
            : null,
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15, height: 1.5)),
          const Spacer(),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue, width: on ? 6 : 2),
            ),
          ),
        ],
      ),
    ),
  );
}
