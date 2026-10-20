import 'package:flutter/material.dart';

import '../../features/home/domain/home_models.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';

/// «إعلان» pill — required on every paid placement.
class AdPill extends StatelessWidget {
  const AdPill({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    padding: large
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.warnBg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      AppStrings.ad,
      style: TextStyle(
        fontSize: large ? 12 : 11,
        height: AppText.lh(large ? 12 : 11),
        fontWeight: FontWeight.w700,
        color: AppColors.warn,
      ),
    ),
  );
}

class RatingLine extends StatelessWidget {
  const RatingLine({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.starSize = 13,
  });
  final String text;
  final double fontSize;
  final double starSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppSvgIcon(AppIcon.star, color: AppColors.gold, size: starSize),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: AppText.lh(fontSize),
          color: AppColors.grey,
        ),
      ),
    ],
  );
}

/// Compact page row used on home «صفحات مميزة».
class PageTile extends StatelessWidget {
  const PageTile({super.key, required this.page, this.onTap});
  final PageSummary page;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1)),
            BoxShadow(color: AppColors.cardRing, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                page.name.characters.first,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.504630,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page.name,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.492593,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const AppSvgIcon(
                      AppIcon.verified,
                      color: AppColors.blue,
                      size: 14,
                      strokeWidth: 2.2,
                    ),
                  ],
                ),
                RatingLine(
                  text: '${page.rating} · ${AppStrings.dealsCount(page.deals)}',
                ),
              ],
            ),
            const Spacer(),
            if (page.isAd) const AdPill(),
          ],
        ),
      ),
    );
  }
}
