import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/page_tile.dart';
import '../data/home_providers.dart';
import '../domain/home_models.dart';
import 'widgets/home_header.dart';
import 'widgets/home_sections.dart';
import 'widgets/live_request_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Live card overlaps the header by this much (design: margin-top -72).
  static const _overlap = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider);
    void soon() => context.push(Routes.comingSoon);
    return Scaffold(
      body: Stack(
        children: [
          home.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
            error: (e, _) => Center(child: Text('$e')),
            data: (d) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeader(
                    data: d,
                    onBell: soon,
                    onLocation: soon,
                    onStory: (_) => soon(),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_overlap),
                    child: _Body(data: d, onSoon: soon),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: AppBottomNav(
              current: NavTab.home,
              onTab: (t) => t == NavTab.home ? null : soon(),
              onPost: soon,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.onSoon});
  final HomeData data;
  final VoidCallback onSoon;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.liveRequest != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LiveRequestCard(request: d.liveRequest!, onCompare: onSoon),
          ),
        PostRequestCta(onTap: onSoon),
        ActivityTicker(items: d.ticker),
        StatsRow(stats: d.stats),
        SectionTitle(AppStrings.secTrending, onSeeAll: onSoon),
        CategoryBento(
          categories: d.categories,
          governorate: d.governorate,
          onTap: (_) => onSoon(),
        ),
        SectionTitle(AppStrings.secNow, onSeeAll: onSoon),
        LiveFeedCard(items: d.feed),
        if (d.deals.isNotEmpty) ...[
          const SectionTitle(AppStrings.secDeals),
          DealsStrip(deals: d.deals),
        ],
        if (d.ad != null) ...[
          const SectionTitle(AppStrings.secAds),
          SponsoredBanner(ad: d.ad!, onTap: onSoon),
        ],
        SectionTitle(
          AppStrings.secFeatured,
          onSeeAll: () => context.push(Routes.featuredPages),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < d.featuredPages.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                PageTile(page: d.featuredPages[i], onTap: onSoon),
              ],
            ],
          ),
        ),
        // Room for the floating nav (minus the overlap pulled up above).
        const SizedBox(height: 120 - HomeScreen._overlap),
      ],
    );
  }
}
