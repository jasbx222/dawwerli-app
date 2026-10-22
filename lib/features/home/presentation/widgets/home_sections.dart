import 'dart:async';

import 'package:flutter/material.dart';

import '../../../store/presentation/widgets/store_widgets.dart';

import '../../../../core/widgets/app_image.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/home_models.dart';
import 'ticker_marquee.dart';

final _ring = BoxShadow(color: AppColors.cardRing, spreadRadius: 1);

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
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: AppSvgIcon(
                                    AppIcon.zap,
                                    color: AppColors.goldSoft,
                                    size: 13,
                                    strokeWidth: 2.1,
                                  ),
                                ),
                                const TextSpan(text: ' '),
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [_ring],
    );
    if (stats.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(10),
        decoration: deco,
        child: Row(
          children: [
            SizedBox(
              width: 26,
              height: 33,
              child: Center(
                child: AppSvgIcon(
                  AppIcon.barChart,
                  size: 22,
                  color: AppColors.blue,
                ),
              ),
            ),
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
      if (stats.avgFirstOfferMinutes != null)
        (
          AppStrings.minutesShort(stats.avgFirstOfferMinutes!),
          AppStrings.statFirstOffer,
        ),
    ];
    if (cells.isEmpty) return const SizedBox.shrink();
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
                      style: TextStyle(
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
      // Floating tile: shadow + badge drawn above the clip so nothing is cut.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x400B1A3F),
              offset: Offset(0, 10),
              blurRadius: 22,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // CSS: background-size:cover; background-position:center
                  AppImage(
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
                ],
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
                    child: EmojiText(
                      badge.$1,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.510101,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              right: 12,
              left: 8,
              child: Text(
                cat.name,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [_ring],
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
                      // CSS 1px renders as 2 device px at the design's DPR.
                      bottom: BorderSide(
                        color: Color(0xFFF1ECE0),
                        width: 2 / AppText.designDpr,
                      ),
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
                      image: appImage(items[i].image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(20.94),
                      child: Text(
                        items[i].category,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.496032,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(19.5),
                      child: Text(
                        items[i].governorate,
                        style: TextStyle(
                          fontSize: 12,
                          height: 19.5000 / 12,
                          color: AppColors.grey,
                        ),
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

/// Home «منتجات أعلى الصفحات تقييماً»: horizontal row of product cards.
/// A plain Row (not a fixed-height ListView) so the cards keep their natural
/// height under any text scale.
/// Horizontal strip of product cards. Card width is a fraction of the
/// screen (about 2.3 cards on phones, more on tablets and the web) so the
/// next card always peeks in at the end edge; all cards share one height.
class ProductStrip extends StatelessWidget {
  const ProductStrip({super.key, required this.products});
  final List<HomeProduct> products;

  static const gap = 12.0;
  static const side = 16.0;

  /// Visible cards for a strip [width]; the fraction leaves the peek.
  static double visibleFor(double width) => width < 600
      ? 2.25
      : width < 1000
      ? 3.4
      : 4.4;

  static double cardWidthFor(double width) {
    final v = visibleFor(width);
    return ((width - side - gap * v.floor()) / v).clamp(148.0, 250.0);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = cardWidthFor(box.maxWidth);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Room for the card shadow; start/end follow RTL.
        padding: const EdgeInsetsDirectional.fromSTEB(side, 4, side, 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < products.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: w,
                  child: StoreProductCard(data: homeProductCard(products[i])),
                ),
              ],
            ],
          ),
        ),
      );
    },
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardRing),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 86,
                width: double.infinity,
                child: AppImage(d.image, fit: BoxFit.cover),
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
      },
    ),
  );
}

class AdSlider extends StatefulWidget {
  const AdSlider({super.key, required this.ads, required this.onTap});
  final List<AdBanner> ads;
  final ValueChanged<AdBanner> onTap;

  @override
  State<AdSlider> createState() => _AdSliderState();
}

class _AdSliderState extends State<AdSlider> {
  late final PageController _page = PageController();
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.ads.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_page.hasClients || widget.ads.length < 2) return;
        final next = (_index + 1) % widget.ads.length;
        _page.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void didUpdateWidget(AdSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.ads.length) _index = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = widget.ads;
    if (ads.length == 1) {
      return SponsoredBanner(
        ad: ads.first,
        onTap: () => widget.onTap(ads.first),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _page,
            itemCount: ads.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) =>
                SponsoredBanner(ad: ads[i], onTap: () => widget.onTap(ads[i])),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < ads.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == _index ? 14 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.gold : AppColors.grey,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SponsoredBanner extends StatelessWidget {
  const SponsoredBanner({super.key, required this.ad, this.onTap});
  final AdBanner ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = ad.image;
    final hasImage = image != null && image.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment(-0.866, -0.5),
            end: Alignment(0.866, 0.5),
            colors: [AppColors.navy, AppColors.blue, Color(0xFF2F5FD0)],
            stops: [0, .6, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) AppImage(image, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.navy.withValues(alpha: hasImage ? .05 : .15),
                    AppColors.navy.withValues(alpha: hasImage ? .78 : .45),
                  ],
                  stops: const [.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      AppStrings.ad,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ad.pageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  if (ad.headline.isNotEmpty)
                    Text(
                      ad.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.white,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      AppStrings.viewPage,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (ad.discountPercent > 0)
              Positioned(
                left: 16,
                top: 16,
                child: Text(
                  '${ad.discountPercent}% ${AppStrings.discount}',
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldSoft,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
