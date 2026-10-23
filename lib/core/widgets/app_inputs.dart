import 'package:flutter/material.dart';

import 'category_icon.dart';
import 'emoji_text.dart';

import 'exact_line.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ExactLine(fontSize: 13, child: Text(text, style: AppText.label)),
  );
}

/// Input shell (`.inp`), focused variant draws the blue ring.
class InputShell extends StatelessWidget {
  const InputShell({
    super.key,
    required this.child,
    this.focused = false,
    this.exactLine = true,
  });

  final Widget child;
  final bool focused;

  /// Pin the content to one 15px design line (22.39); off for multi-line/fixed boxes.
  final bool exactLine;

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
        color: AppColors.surface,
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
        style: TextStyle(fontSize: 15, height: 1.492593, color: AppColors.ink),
        child: exactLine ? ExactLine(fontSize: 15, child: child) : child,
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
    this.obscureText = false,
    this.onSubmitted,
  });

  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final rtl =
        (textDirection ?? Directionality.of(context)) == TextDirection.rtl;
    // EditableText reserves a caret margin (1px gap + 2px caret) at the line end,
    // which in RTL pushes the text 3px in from the right edge vs. the HTML input.
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textDirection: textDirection,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      style:
          style ??
          TextStyle(
            fontFamily: AppText.family,
            fontSize: 15,
            height: 1.492593,
            color: AppColors.ink,
          ),
      decoration: const InputDecoration.collapsed(hintText: ''),
    );
    return rtl
        ? Transform.translate(offset: const Offset(3, 0), child: field)
        : field;
  }
}

class AppChip extends StatelessWidget {
  const AppChip(
    this.label, {
    super.key,
    this.selected = false,
    this.gold = false,
    this.onTap,
    this.width,
    this.categoryKey,
  });

  final String label;
  final bool selected;

  /// Category slug: draws its SVG icon before the label in the text colour.
  final String? categoryKey;

  /// Fixed outer width (design-measured) so Chrome/Flutter glyph-width
  /// differences don't shift neighbouring chips; label is centred.
  final double? width;

  /// `.chip.g`: soft gold suggestion chip (no ring).
  final bool gold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.white
        : (gold ? AppColors.warn : AppColors.ink);
    final text = ExactLine(
      fontSize: 13,
      child: EmojiText(
        label,
        style: TextStyle(
          fontSize: 13,
          height: 1.500000,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        alignment: width == null ? null : Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: width == null ? 13 : 0,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue
              : (gold ? AppColors.warnBg : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: selected || gold
              ? null
              : [BoxShadow(color: AppColors.border, spreadRadius: 1.5)],
        ),
        child: categoryKey == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIcon(
                    categoryKey,
                    size: 16,
                    color: selected ? AppColors.white : AppColors.blue,
                  ),
                  const SizedBox(width: 6),
                  text,
                ],
              ),
      ),
    );
  }
}
