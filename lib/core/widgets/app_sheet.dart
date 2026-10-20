import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.sheet`: white, 28px top radius, pad 14/20/34, grab 44×5 (#DDD6C6, mb 16).
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x40000000),
          offset: Offset(0, -20),
          blurRadius: 50,
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6C6),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}
