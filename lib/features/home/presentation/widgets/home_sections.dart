import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/home_models.dart';
import 'ticker_marquee.dart';

const _ring = BoxShadow(color: AppColors.cardRing, spreadRadius: 1);

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            height: 1.504630,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                AppStrings.seeAll,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.500000,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class PostRequestCta extends StatelessWidget {
  const PostRequestCta({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99E8B33A),
            offset: Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              AppIcon.plus,
              color: AppColors.white,
              strokeWidth: 2.4,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.postNew,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.508170,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Opacity(
                opacity: .75,
                child: const Text(
                  AppStrings.postNewSub,
                  style: TextStyle(fontSize: 12, height: 23.8333 / 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Tilted navy strip of anonymised live activity (category · governorate · offers).
class ActivityTicker extends StatelessWidget {
  const ActivityTicker({super.key, required this.items});
  final List<FeedItem> items;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: 6 + 14 + 39 + 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 6 + 14,
              right: -20,
              width: 430,
              height: 39,
              child: Transform.rotate(
                angle: -1.5 * 3.14159265 / 180,
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TickerMarquee(
                    children: [
                      for (final f in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: '⚡ '),
                                TextSpan(
                                  text: f.category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.goldSoft,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' · ${f.governorate} · ${AppStrings.offersCount(f.offers)}',
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.500000,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real stats only; each metric hidden until it passes the admin threshold.
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.stats});
  final HomeStats stats;

  @override
  Widget build(BuildContext context) {
    final deco = BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [_ring],
    );
    if (stats.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(10),
        decoration: deco,
        child: const Row(
          children: [
            Text('📊', style: TextStyle(fontSize: 22, height: 33 / 22)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.statsSoon,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.496032,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppStrings.statsSoonSub,
                    style: TextStyle(
                      fontSize: 11,
                      height: 23.8333 / 11,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final cells = <(String, String)>[
      if (stats.verifiedPages != null)
        (thousands(stats.verifiedPages!), AppStrings.statPages),
      if (stats.governorates != null)
        ('${stats.governorates}', AppStrings.statGovs),
      if (stats.avgFirstOfferMinutes != null)
        (
          AppStrings.minutesShort(stats.avgFirstOfferMinutes!),
          AppStrings.statFirstOffer,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: deco,
                child: Column(
                  children: [
                    Text(
                      cells[i].$1,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.508170,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                    Text(
                      cells[i].$2,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 23.8333 / 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CategoryBento extends StatelessWidget {
  const CategoryBento({
    super.key,
    required this.categories,
    required this.governorate,
    this.onTap,
  });
  final List<TrendingCategory> categories;
  final String governorate;
  final ValueChanged<TrendingCategory>? onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.length < 5) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 10.0, rowH = 118.0;
          final fr = (c.maxWidth - 2 * gap) / 3.25;
          Widget tile(TrendingCategory cat, {bool big = false}) => _BentoTile(
            cat: cat,
            big: big,
            governorate: governorate,
            onTap: () => onTap?.call(cat),
          );
          return SizedBox(
            height: rowH * 2 + gap,
            child: Row(
              children: [
                SizedBox(
                  width: fr * 1.25,
                  child: tile(categories[0], big: true),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: tile(categories[1])),
                            const SizedBox(width: gap),
                            Expanded(child: tile(categories[2])),
                          ],
                        ),
                      ),
                      const SizedBox(height: gap),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: tile(categories[3])),
                            const SizedBox(width: gap),
                            Expanded(child: tile(categories[4])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.cat,
    required this.big,
    required this.governorate,
    this.onTap,
  });
  final TrendingCategory cat;
  final bool big;
  final String governorate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = switch (cat.badge) {
      CategoryBadge.trending => (
        AppStrings.trendingIn(governorate),
        AppColors.goldSoft,
      ),
      CategoryBadge.isNew => (AppStrings.badgeNew, AppColors.white),
      CategoryBadge.none => null,
    };
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // CSS: background-size:cover; background-position:center
            Image.asset(
              cat.image,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC0F1E3D), Color(0x000F1E3D)],
                  stops: [0, .6],
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 10,
                child: Transform.rotate(
                  angle: -4 * 3.14159265 / 180,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badge.$2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badge.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.510101,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              right: 12,
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: big ? 18 : 14,
                  height: AppText.lh(big ? 18 : 14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveFeedCard extends StatelessWidget {
  const LiveFeedCard({super.key, required this.items});
  final List<FeedItem> items;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [_ring],
    ),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: i == items.length - 1
                ? null
                : const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1ECE0)),
                    ),
                  ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(items[i].image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].category,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.496032,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      items[i].governorate,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 19.5000 / 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    AppStrings.offersCount(items[i].offers),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.504630,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class DealsStrip extends StatelessWidget {
  const DealsStrip({super.key, required this.deals});
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 86 + 18 + 19 + 24,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: deals.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final d = deals[i];
        return Container(
          width: 150,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardRing),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 86,
                width: double.infinity,
                child: Image.asset(d.image, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.category} · ${d.pageName}',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.500000,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: AppStrings.save),
                          TextSpan(
                            text: thousands(d.saved),
                            style: const TextStyle(
                              color: Color(0xFF0B6E66),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const TextSpan(text: AppStrings.vsHighest),
                        ],
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 23.8333 / 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class SponsoredBanner extends StatelessWidget {
  const SponsoredBanner({super.key, required this.ad, this.onTap});
  final AdBanner ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            // CSS 120deg
            begin: Alignment(-0.866, -0.5),
            end: Alignment(0.866, 0.5),
            colors: [AppColors.navy, AppColors.blue, Color(0xFF2F5FD0)],
            stops: [0, .6, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -30,
              bottom: -50,
              width: 170,
              height: 170,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: .08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        AppStrings.sponsored,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.510101,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ad.pageName,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.501462,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Opacity(
                      opacity: .85,
                      child: Text(
                        ad.headline,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 19.5000 / 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 28,
              child: Column(
                children: [
                  Text(
                    '${ad.discountPercent}%',
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.discount,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.504630,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  AppStrings.viewPage,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.504630,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
