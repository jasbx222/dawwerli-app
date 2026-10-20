import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/offer_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/offer.dart';

export '../../../../core/widgets/pill.dart';
import '../../../../core/widgets/pill.dart';

final _deg7 = -7 * 3.141592653589793 / 180;

/// Icons only used in this flow (24×24, stroke 2, from 14/14b).
enum OfferIcon {
  fire(
    '<path d="M12 22c4 0 7-2.8 7-7 0-3.5-2.2-6-4-8 0 2.5-1.5 4-3 4 0-3-1-6-4-9 0 4-5 7.5-5 13 0 4.2 3 7 7 7z"/>',
  ),
  truck(
    '<path d="M3 6h11v10H3zM14 9h4l3 3v4h-7"/><circle cx="7" cy="17.5" r="1.8"/><circle cx="17" cy="17.5" r="1.8"/>',
  ),
  bulb(
    '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-4 10.5c.8.8 1 1.5 1 2.5h6c0-1 .2-1.7 1-2.5A6 6 0 0 0 12 3z"/>',
  ),
  okHand('<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.5 2.5L16 9.5"/>'),
  target(
    '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5"/>',
  ),
  ban('<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>'),
  refresh('<path d="M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5"/>'),
  alert(
    '<path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
  );

  const OfferIcon(this.body);
  final String body;

  Widget of(Color c, double size) {
    final hex =
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
    );
  }
}

/// SVG ✓ sized like the glyph at [size] font size, baseline-aligned.
WidgetSpan checkSpan(double size, Color c) => WidgetSpan(
  alignment: PlaceholderAlignment.middle,
  child: AppSvgIcon(AppIcon.check, size: size * .8, color: c, strokeWidth: 3),
);

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

final cardShadow = BoxShadow(
  color: Color(0x660B1A3F),
  offset: Offset(0, 14),
  blurRadius: 30,
  spreadRadius: -20,
);

/// Inline star (13px, baseline-aligned like an inline SVG).
const InlineSpan starSpan = WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: AppSvgIcon(AppIcon.star, size: 13, color: AppColors.gold),
);

String rating1(double r) => r.toStringAsFixed(1);

/// Offer row card on 11/13 (`.card` + 72px thumb + price column).
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.cheapest,
    this.onTap,
  });
  final Offer offer;
  final bool cheapest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final o = offer;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                cardShadow,
                BoxShadow(
                  color: cheapest ? AppColors.gold : AppColors.cardRing,
                  spreadRadius: cheapest ? 2 : 1,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    o.image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.pageName,
                        style: AppText.strong.copyWith(
                          fontSize: 15,
                          height: AppText.lh(15),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            starSpan,
                            TextSpan(
                              text: OfferStrings.ratingDeals(
                                rating1(o.rating),
                                o.deals,
                                more: o.trusted,
                              ),
                            ),
                          ],
                        ),
                        style: AppText.muted,
                      ),
                      // Chrome wraps the inline «موثوقة ✓» pill onto its own line here.
                      if (o.trusted)
                        Text.rich(
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Pill(
                              OfferStrings.trustedCheck,
                              check: true,
                              bg: AppColors.blueTint,
                              fg: AppColors.blue,
                              padding: EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                            ),
                          ),
                          style: AppText.muted,
                        ),
                      Text.rich(
                        TextSpan(
                          children: [
                            iconSpan(OfferIcon.truck, AppColors.grey, 14),
                            TextSpan(
                              text: ' ${OfferStrings.delivers(o.delivery)}',
                            ),
                          ],
                        ),
                        style: AppText.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      thousands(o.price),
                      style: AppText.number.copyWith(
                        fontSize: 19,
                        height: AppText.lh(19),
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                    Text(OfferStrings.iqd, style: AppText.muted),
                  ],
                ),
              ],
            ),
          ),
          if (o.sponsored)
            const Positioned(
              top: -10,
              left: 14,
              child: Pill(
                OfferStrings.sponsored,
                bg: AppColors.warnBg,
                fg: AppColors.warn,
              ),
            ),
          if (cheapest)
            const Positioned(
              top: -12,
              right: 14,
              child: Sticker(OfferStrings.cheapest),
            ),
        ],
      ),
    );
  }
}

/// `.li`: label (muted) · value (bold, pushed to the far end), 13px vertical pad.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueSize = 14.5,
    this.divider = true,
  });
  final String label;
  final String value;
  final double valueSize;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: divider
        ? BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          )
        : null,
    child: Row(
      children: [
        Text(label, style: AppText.muted),
        const SizedBox(width: 12),
        const Spacer(),
        Text(
          value,
          style: AppText.strong.copyWith(
            fontSize: valueSize,
            height: AppText.lh(valueSize),
          ),
        ),
      ],
    ),
  );
}

/// `.btn` with a leading 20px icon (gap 8), e.g. «افتح الواتساب».
class IconLabelButton extends StatelessWidget {
  const IconLabelButton({
    super.key,
    required this.label,
    required this.icon,
    required this.bg,
    this.onPressed,
  });
  final String label;
  final AppIcon icon;
  final Color bg;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(icon, size: 20, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.button.copyWith(
                color: AppColors.white,
                height: AppText.lh(16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Transparent card with a 1.5px dashed #CBD5E1 border (pad 16).
class DashedCard extends StatelessWidget {
  const DashedCard({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.padding = 17.5,
  });
  final Widget child;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _Dashed(radius),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class _Dashed extends CustomPainter {
  _Dashed(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.75),
      Radius.circular(radius - .75),
    );
    final p = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 4.5), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// «🚫 لا تحوّل…» card with the ban emoji drawn as a red SVG.
class NoPrepayText extends StatelessWidget {
  const NoPrepayText({super.key});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: OfferIcon.ban.of(const Color(0xFFD92D20), 16),
        ),
        TextSpan(text: ' ${OfferStrings.noPrepay}'),
      ],
    ),
    strutStyle: const StrutStyle(
      fontFamily: AppText.family,
      fontSize: 14,
      height: 1.5,
      forceStrutHeight: true,
    ),
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.dangerText,
    ),
  );
}

/// Inline SVG icon span (replaces an emoji inside a text line).
WidgetSpan iconSpan(OfferIcon i, Color c, double size) =>
    WidgetSpan(alignment: PlaceholderAlignment.middle, child: i.of(c, size));
