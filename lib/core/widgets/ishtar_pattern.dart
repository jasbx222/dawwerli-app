import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Ishtar Gate brick + rosette tile (56×56), identical to the design SVG.
class IshtarPatternPainter extends CustomPainter {
  const IshtarPatternPainter();

  static const tile = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.goldSoft.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = AppColors.goldSoft.withValues(alpha: .35);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        final path = Path()
          ..moveTo(x, y + 14)
          ..lineTo(x + 56, y + 14)
          ..moveTo(x, y + 42)
          ..lineTo(x + 56, y + 42)
          ..moveTo(x + 14, y)
          ..lineTo(x + 14, y + 14)
          ..moveTo(x + 42, y + 14)
          ..lineTo(x + 42, y + 42)
          ..moveTo(x + 14, y + 42)
          ..lineTo(x + 14, y + 56);
        canvas.drawPath(path, line);
        canvas.save();
        canvas.translate(x + 28, y + 28);
        canvas.drawCircle(Offset.zero, 3, fill);
        for (var i = 0; i < 8; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 4);
          canvas.drawOval(
            Rect.fromCenter(
              center: const Offset(0, -8),
              width: 5.2,
              height: 10,
            ),
            fill,
          );
          canvas.restore();
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gradient background with the Ishtar tile pattern on top.
class IshtarBackground extends StatelessWidget {
  const IshtarBackground({
    super.key,
    required this.gradient,
    this.borderRadius,
    this.child,
  });

  final Gradient gradient;
  final BorderRadius? borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: CustomPaint(painter: const IshtarPatternPainter(), child: child),
      ),
    );
  }
}

/// Elliptical radial gradient like CSS `radial-gradient(Wx% Hy% at X Y, ...)`.
class EllipseTransform extends GradientTransform {
  const EllipseTransform(this.rx, this.ry, this.center);

  /// Radii as fractions of the box width / height; center as fractions (0..1).
  final double rx, ry;
  final Offset center;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final c = Offset(
      bounds.left + bounds.width * center.dx,
      bounds.top + bounds.height * center.dy,
    );
    final base = bounds.shortestSide / 2;
    final sx = bounds.width * rx / base;
    final sy = bounds.height * ry / base;
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

RadialGradient cssRadial({
  required double rx,
  required double ry,
  required Offset at,
  required List<Color> colors,
  required List<double> stops,
}) {
  return RadialGradient(
    center: Alignment(at.dx * 2 - 1, at.dy * 2 - 1),
    radius: 0.5,
    colors: colors,
    stops: stops,
    transform: EllipseTransform(rx, ry, at),
  );
}
