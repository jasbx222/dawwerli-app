import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';
import 'app_inputs.dart';

/// Label + `.inp` text field that owns its focus ring (`.inp.f`).
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    this.label,
    required this.controller,
    this.hint,
    this.trailing,
    this.ltr = false,
    this.keyboardType,
    this.lines = 1,
    this.onChanged,
    this.style,
  });
  final String? label;
  final TextEditingController controller;
  final String? hint;
  final Widget? trailing;
  final bool ltr;
  final TextInputType? keyboardType;
  final int lines;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.lines > 1;
    final field = multi
        ? TextField(
            controller: widget.controller,
            focusNode: _focus,
            minLines: widget.lines,
            maxLines: widget.lines + 2,
            onChanged: widget.onChanged,
            style: widget.style ?? AppText.body.copyWith(fontSize: 15),
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: AppText.muted,
            ),
          )
        : BareTextField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: widget.keyboardType,
            style: widget.style,
            onChanged: widget.onChanged,
            textDirection: widget.ltr ? TextDirection.ltr : null,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) FieldLabel(widget.label!),
        InputShell(
          focused: _focus.hasFocus,
          exactLine: !multi && widget.style == null,
          child: Row(
            textDirection: widget.ltr ? TextDirection.ltr : null,
            children: [
              Expanded(child: field),
              if (widget.trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Wrap of selectable chips; [limit] collapses the rest behind «+N».
class ChipPicker extends StatefulWidget {
  const ChipPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.limit,
    this.extra,
  });
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int? limit;

  /// Trailing chip such as «+ صنف».
  final Widget? extra;

  @override
  State<ChipPicker> createState() => _ChipPickerState();
}

class _ChipPickerState extends State<ChipPicker> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final lim = widget.limit;
    final shown = _all || lim == null
        ? widget.options
        : widget.options.take(lim).toList();
    final hidden = widget.options.length - shown.length;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final o in shown)
          AppChip(
            o,
            selected: widget.selected.contains(o),
            onTap: () => widget.onToggle(o),
          ),
        if (hidden > 0)
          AppChip('+$hidden', onTap: () => setState(() => _all = true)),
        ?widget.extra,
      ],
    );
  }
}

/// Dashed upload box (receipt, evidence photo); filled = check + label.
class UploadBox extends StatelessWidget {
  const UploadBox({
    super.key,
    required this.label,
    required this.done,
    required this.onTap,
    this.doneLabel = 'انرفعت الصورة',
  });
  final String label;
  final String doneLabel;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: CustomPaint(
      painter: done ? null : _DashedBorder(AppColors.border),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: done
            ? BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.input),
              )
            : null,
        child: Row(
          children: [
            AppSvgIcon(
              done ? AppIcon.check : AppIcon.image,
              color: done ? AppColors.success : AppColors.blue,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              done ? doneLabel : label,
              style: AppText.body.copyWith(
                color: done ? AppColors.success : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.input),
        ),
      );
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
