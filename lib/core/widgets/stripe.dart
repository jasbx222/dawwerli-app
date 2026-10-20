import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Diagonal gold stripe band (CSS repeating-linear-gradient 135deg, 7px) at .35 opacity.
class GoldStripe extends StatelessWidget {
  const GoldStripe({super.key});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: .35,
    child: CustomPaint(painter: _StripePainter(), size: Size.infinite),
  );
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // repeating-linear-gradient(135deg, gold 0 7px, transparent 7px 14px)
    final p = Paint()..color = AppColors.goldSoft;
    canvas.clipRect(Offset.zero & size);
    const period = 14.0, band = 7.0;
    const k =
        1.4142135623730951; // diagonal stripes, period measured along 135°
    for (
      var x = -size.height * 2;
      x < size.width + size.height * 2;
      x += period * k
    ) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + band * k, 0)
        ..lineTo(x + band * k - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
