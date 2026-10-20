import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppText.label),
  );
}

/// Input shell (`.inp`), focused variant draws the blue ring.
class InputShell extends StatelessWidget {
  const InputShell({super.key, required this.child, this.focused = false});

  final Widget child;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer height = line + 2×13 padding + 2×1.5 border (CSS); focused uses a 2px border (UIUX),
      // so padding shrinks by .5 to keep the same size.
      padding: EdgeInsets.symmetric(
        horizontal: focused ? 13.5 : 14,
        vertical: focused ? 12.5 : 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: focused ? AppColors.blue : AppColors.border,
          width: focused ? 2 : 1.5,
        ),
        boxShadow: focused
            // CSS: box-shadow 0 0 0 4px rgba(31,78,156,.12)
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: .12),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 15,
          height: 1.4667,
          color: AppColors.navy,
        ),
        child: child,
      ),
    );
  }
}

/// Borderless text field to place inside [InputShell].
class BareTextField extends StatelessWidget {
  const BareTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.style,
    this.keyboardType,
    this.textDirection,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textDirection: textDirection,
      onChanged: onChanged,
      style:
          style ??
          const TextStyle(
            fontFamily: AppText.family,
            fontSize: 15,
            height: 1.4667,
            color: AppColors.navy,
          ),
      decoration: const InputDecoration.collapsed(hintText: ''),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip(this.label, {super.key, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: selected
              ? null
              : const [BoxShadow(color: AppColors.border, spreadRadius: 1.5)],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.4615,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
