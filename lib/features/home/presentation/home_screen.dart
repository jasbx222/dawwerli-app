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
  const _Body({required this.data, required this.onPost, this.guest = false});
  final HomeData data;
  final VoidCallback onPost;
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
        if (d.banners.isNotEmpty)
          SponsoredBanner(
            ad: d.banners.first,
            onTap: () => context.push(Routes.pageProfile(d.banners.first.pageId)),
          ),
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
        SectionTitle(
          AppStrings.secNow,
          onSeeAll: () => context.push(Routes.feed),
        ),
        LiveFeedCard(items: d.feed),
        if (d.deals.isNotEmpty) ...[
          const SectionTitle(AppStrings.secDeals),
          DealsStrip(deals: d.deals),
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
                PageTile(
                  page: d.featuredPages[i],
                  onTap: () =>
                      context.push(Routes.pageProfile(d.featuredPages[i].id)),
                ),
              ],
            ],
          ),
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
