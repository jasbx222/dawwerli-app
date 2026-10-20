import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/home_models.dart';

class LiveRequestCard extends StatelessWidget {
  const LiveRequestCard({super.key, required this.request, this.onCompare});
  final LiveRequest request;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x730B1A3F), offset: Offset(0, 20), blurRadius: 40, spreadRadius: -18),
          BoxShadow(color: Color(0x141E40AF), spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: AssetImage(r.image), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: const TextStyle(fontSize: 16, height: 1.5000, fontWeight: FontWeight.w700)),
                    Text(AppStrings.reachedPages(r.reachedPages, r.governorate),
                        style: const TextStyle(fontSize: 12, height: 1.5000, color: AppColors.grey)),
                  ],
                ),
              ),
              const _LivePill(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(AppStrings.pagesCompeting(r.offerPrices.length),
                  style: const TextStyle(fontSize: 13, height: 1.4615, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(AppStrings.slotsLeft(r.maxOffers - r.offerPrices.length),
                  style: const TextStyle(fontSize: 13, height: 1.4615, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  for (var i = 0; i < r.maxOffers; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(
                      child: i < r.offerPrices.length
                          ? _Slot(price: r.offerPrices[i], cheapest: i == 0)
                          : const _EmptySlot(),
                    ),
                  ],
                ],
              ),
              if (r.offerPrices.isNotEmpty)
                Positioned(
                  right: -8,
                  top: 50,
                  child: Transform.rotate(
                    angle: -8 * 3.14159265 / 180,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sticker,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0xB3FF7A59), offset: Offset(0, 4), blurRadius: 10, spreadRadius: -3),
                        ],
                      ),
                      child: const Text(AppStrings.goodOffer,
                          style: TextStyle(fontSize: 11, height: 1.5455, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const AppSvgIcon(AppIcon.clock, color: Color(0xFF475569), size: 16),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: AppStrings.closesIn),
                  TextSpan(
                    text: hhmm(r.closesIn),
                    style: AppText.number.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ]),
                style: const TextStyle(fontSize: 13, height: 1.4615, color: Color(0xFF475569)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCompare,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppStrings.compareOffers,
                          style: TextStyle(fontSize: 14, height: 1.5000, fontWeight: FontWeight.w700, color: AppColors.white)),
                      SizedBox(width: 6),
                      AppSvgIcon(AppIcon.chevronLeft, color: AppColors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.turquoise,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x4014B8A6), spreadRadius: 4)],
              ),
            ),
            const SizedBox(width: 6),
            const Text(AppStrings.live,
                style: TextStyle(fontSize: 12, height: 1.5000, fontWeight: FontWeight.w700, color: Color(0xFF0B6E66))),
          ],
        ),
      );
}

class _Slot extends StatelessWidget {
  const _Slot({required this.price, required this.cheapest});
  final int price;
  final bool cheapest;

  @override
  Widget build(BuildContext context) {
    final fg = cheapest ? AppColors.white : AppColors.navy;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 62,
          decoration: BoxDecoration(
            color: cheapest ? AppColors.blue : AppColors.slotBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cheapest ? AppColors.blue : AppColors.blueRing, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(thousands(price), style: TextStyle(fontSize: 14, height: 1.5000, fontWeight: FontWeight.w700, color: fg)),
              Text(AppStrings.currency,
                  style: TextStyle(fontSize: 10, height: 1.5000, color: cheapest ? AppColors.blueRing : AppColors.grey)),
            ],
          ),
        ),
        if (cheapest)
          Positioned(
            top: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(99)),
              child: const Text(AppStrings.cheapest,
                  style: TextStyle(fontSize: 10, height: 1.5000, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ),
          ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedRRect(),
        child: SizedBox(
          height: 62,
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle),
            ),
          ),
        ),
      );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius((Offset.zero & size).deflate(.75), const Radius.circular(14));
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
