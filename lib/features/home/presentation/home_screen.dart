import 'dart:async';

import 'package:flutter/material.dart';

import '../../guest/guest.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/page_tile.dart';
import '../data/home_notice.dart';
import '../data/home_providers.dart';
import '../../post/presentation/widgets/post_widgets.dart';
import '../../../core/widgets/app_icons.dart';
import '../../offers/data/offers_providers.dart';
import '../../offers/domain/offer.dart';
import '../domain/home_models.dart';
import 'widgets/home_header.dart';
import 'widgets/home_sections.dart';
import 'widgets/live_request_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Live card overlaps the header by this much (design: margin-top -72).
  static const _overlap = 72.0;

  /// Nav offset (18) + nav height (70) + clearance above it (32).
  static const navClearance = 18.0 + 70 + 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider);
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
                    guest: ref.watch(guestProvider),
                    onBell: () => memberOnly(
                      context,
                      ref,
                      () => context.go(Routes.notifications),
                    ),
                    onLocation: () => memberOnly(
                      context,
                      ref,
                      () => context.push(Routes.region),
                    ),
                    onStory: (s) =>
                        context.push(Routes.pageProfile(s.pageId)),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_overlap),
                    child: _Body(
                      data: d,
                      offers: (!ref.watch(guestProvider) && d.liveRequest != null)
                          ? ref.watch(offersProvider(d.liveRequest!.id)).value?.offers ?? const []
                          : const [],
                      guest: ref.watch(guestProvider),
                      onPost: () => memberOnly(
                        context,
                        ref,
                        () => context.push(Routes.post),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ref.watch(homeNoticeProvider) case final text?)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18 + 70 + 12 + MediaQuery.viewPaddingOf(context).bottom,
              child: _TimedNotice(
                key: ValueKey(text),
                onDone: () => ref.read(homeNoticeProvider.notifier).clear(),
                child: OfflineBanner(
                  text,
                  icon: AppIcon.check,
                  iconColor: AppColors.gold,
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18 + MediaQuery.viewPaddingOf(context).bottom,
            child: AppBottomNav(
              current: NavTab.home,
              onTab: (t) => switch (t) {
                NavTab.home => null,
                NavTab.requests => memberOnly(
                  context,
                  ref,
                  () => context.go(Routes.myRequests),
                ),
                NavTab.notifications => memberOnly(
                  context,
                  ref,
                  () => context.go(Routes.notifications),
                ),
                NavTab.account => memberOnly(
                  context,
                  ref,
                  () => context.go(Routes.account),
                ),
              },
              onPost: () =>
                  memberOnly(context, ref, () => context.push(Routes.post)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.onPost,
    this.offers = const [],
    this.guest = false,
  });
  final HomeData data;
  final VoidCallback onPost;
  final List<Offer> offers;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (guest)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GuestCard(),
          )
        else if (d.liveRequest != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LiveRequestCard(
              request: d.liveRequest!,
              onCompare: () => context.push(Routes.offers(d.liveRequest!.id)),
            ),
          ),
        PostRequestCta(onTap: onPost),
        if (offers.isNotEmpty && d.liveRequest != null) ...[
          SectionTitle(
            'العروض',
            onSeeAll: () => context.push(Routes.offers(d.liveRequest!.id)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < offers.length && i < 5; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.push(Routes.offers(d.liveRequest!.id)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: offers[i].sponsored
                            ? Border.all(color: AppColors.gold, width: 1.5)
                            : Border.all(color: AppColors.cardRing),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(offers[i].pageName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(
                                  '${offers[i].price} د.ع',
                                  style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          if (offers[i].sponsored)
                            const Text('مُموّل', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (d.banners.isNotEmpty)
          AdSlider(
            ads: d.banners,
            onTap: (ad) => context.push(Routes.pageProfile(ad.pageId)),
          ),
        if (d.sponsored.isNotEmpty) ...[
          const SectionTitle(AppStrings.secSponsored),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < d.sponsored.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  PageTile(
                    page: d.sponsored[i],
                    adLabel: AppStrings.sponsored,
                    onTap: () =>
                        context.push(Routes.pageProfile(d.sponsored[i].id)),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (d.featuredPages.isNotEmpty) ...[
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
                  PageTile(
                    page: d.featuredPages[i],
                    onTap: () =>
                        context.push(Routes.pageProfile(d.featuredPages[i].id)),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (d.topProducts.isNotEmpty) ...[
          const SectionTitle(AppStrings.secTopProducts),
          ProductStrip(
            products: d.topProducts,
            onTap: (p) => context.push(Routes.product(p.pageId, p.id)),
          ),
        ],
        ActivityTicker(items: d.ticker),
        StatsRow(stats: d.stats),
        SectionTitle(
          AppStrings.secTrending,
          onSeeAll: () => context.push(Routes.categories),
        ),
        CategoryBento(
          categories: d.categories,
          governorate: d.governorate,
          onTap: (c) => context.push(Routes.category(c.id)),
        ),
        // Room for the floating nav: its 18px offset + 70px bar + 32px clearance
        // + the system bottom inset (Android gesture/nav bar), minus the overlap
        // the body is pulled up by.
        SizedBox(
          height:
              HomeScreen.navClearance +
              MediaQuery.viewPaddingOf(context).bottom -
              HomeScreen._overlap,
        ),
      ],
    );
  }
}

/// Shows [child] for 3 seconds, then calls [onDone].
class _TimedNotice extends StatefulWidget {
  const _TimedNotice({super.key, required this.child, required this.onDone});
  final Widget child;
  final VoidCallback onDone;
  @override
  State<_TimedNotice> createState() => _TimedNoticeState();
}

class _TimedNoticeState extends State<_TimedNotice> {
  late final _t = Timer(const Duration(seconds: 3), widget.onDone);
  @override
  void initState() {
    super.initState();
    _t;
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
