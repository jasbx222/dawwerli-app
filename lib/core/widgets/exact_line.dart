import 'package:flutter/widgets.dart';

import '../theme/app_typography.dart';

/// Pins a single text line to the design's device-rounded line box
/// (e.g. 13px → 19.5). Flutter rounds a paragraph's height to whole logical px
/// (19.5 → 20), which accumulates ~0.5px per label/chip; this keeps layout exact.
/// The text keeps its natural width; any sub-pixel overflow just paints.
class ExactLine extends StatelessWidget {
  const ExactLine({super.key, required this.fontSize, required this.child});

  final double fontSize;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: AppText.lh(fontSize) * fontSize, child: child);
}

/// Multi-line variant of [ExactLine]: measures how many lines [text] wraps to
/// and sizes the box to `lines × device-rounded line height`.
class ExactText extends StatelessWidget {
  const ExactText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final dir = Directionality.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: dir,
        textScaler: scaler,
      )..layout(maxWidth: c.maxWidth);
      final lines = tp.computeLineMetrics().length;
      tp.dispose();
      final size = style.fontSize ?? 14;
      return SizedBox(
        height: lines * AppText.lh(size) * size,
        child: Text(text, style: style),
      );
    },
  );
}
