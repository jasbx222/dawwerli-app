import 'package:flutter/material.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/countdown.dart';
import '../../../post/presentation/widgets/post_widgets.dart';
import '../../domain/live_request.dart';

/// Offers card on 10: headline, 5 slots (`.slots`, gap 7, h 58), sticker, widen countdown.
class OffersCard extends StatelessWidget {
  const OffersCard({
    super.key,
    required this.offers,
    required this.maxOffers,
    required this.cheapest,
    this.widensAt,
  });

  final List<int> offers;
  final int maxOffers;
  final int cheapest;
  final DateTime? widensAt;

  @override
  Widget build(BuildContext context) {
    final n = offers.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  EmojiText(
                    n == 0
                        ? AppStrings.noOffersYet
                        : AppStrings.pagesFighting(n),
                    style: AppText.strong.copyWith(height: AppText.lh(14)),
                  ),
                  const Spacer(),
                  Text(
                    n == 0
                        ? AppStrings.placesEmpty(maxOffers)
                        : AppStrings.placesLeft(maxOffers - n),
                    style: AppText.muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < maxOffers; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(
                      child: i < n
                          ? _Slot(price: offers[i], cheapest: i == cheapest)
                          : const _EmptySlot(),
                    ),
                  ],
                ],
              ),
              if (widensAt != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 20.94, // 14px line, device-rounded
                  child: Row(
                    children: [
                      const AppSvgIcon(
                        AppIcon.clock,
                        size: 15,
                        color: AppColors.grey,
                      ),
                      const Text(AppStrings.widensIn, style: AppText.muted),
                      const Spacer(),
                      Countdown(
                        until: widensAt!,
                        builder: (context, left) => Text(
                          mss(left.inSeconds),
                          style: AppText.number.copyWith(
                            fontSize: 14,
                            height: AppText.lh(14),
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (n > 0)
          // `.stk` top:96px; right:8px; rotate(-7deg).
          Positioned(
            top: 96,
            right: 8,
            child: Transform.rotate(
              angle: -7 * 3.141592653589793 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sticker,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB3FF7A59),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: EmojiText(
                  AppStrings.goodOffer,
                  style: TextStyle(
                    fontSize: 12,
                    height: AppText.lh(12),
                    fontWeight: FontWeight.w700,
                    color: AppColors.stickerText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.price, required this.cheapest});
  final int price;
  final bool cheapest;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    decoration: BoxDecoration(
      color: cheapest ? AppColors.blue : AppColors.slotBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: cheapest ? AppColors.blue : AppColors.blueRing,
        width: 1.5,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          thousands(price),
          style: TextStyle(
            fontSize: 13.5,
            height: AppText.lh(13.5),
            fontWeight: FontWeight.w700,
            color: cheapest ? AppColors.white : AppColors.navy,
          ),
        ),
        Text(
          AppStrings.currency,
          style: TextStyle(
            fontSize: 10,
            height: AppText.lh(10),
            color: cheapest ? AppColors.blueRing : AppColors.grey,
          ),
        ),
      ],
    ),
  );
}

/// `.sl.e`: white, 1.5px dashed #CBD5E1, centre dot 8px.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRect(),
    child: SizedBox(
      height: 58,
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.75),
      const Radius.circular(13.25),
    );
    canvas.drawRRect(rr, Paint()..color = AppColors.white);
    final p = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paid page card (110px, image + 90° navy gradient), always labelled «إعلان · مُموّل».
class SponsoredCard extends StatelessWidget {
  const SponsoredCard({super.key, required this.page});
  final SponsoredPage page;

  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x660B1A3F),
          offset: Offset(0, 14),
          blurRadius: 30,
          spreadRadius: -20,
        ),
        BoxShadow(color: AppColors.cardRing, spreadRadius: 1),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Design CSS: background-size cover, position default 0 0 (top-left).
          Image.asset(
            page.image,
            fit: BoxFit.cover,
            alignment: Alignment.topLeft,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x1A0F1E3D), Color(0xD90F1E3D)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmallPill(
                  label: AppStrings.sponsored,
                  bg: AppColors.white.withValues(alpha: .2),
                ),
                const SizedBox(height: 6),
                Text(
                  page.name,
                  style: TextStyle(
                    fontSize: 17,
                    height: AppText.lh(17),
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  page.tagline,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: AppText.lh(12.5),
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
