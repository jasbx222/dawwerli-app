import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_sections.dart';
import '../../store/data/store_data.dart';
import '../../store/presentation/widgets/product_card.dart';
import '../../store/presentation/widgets/store_widgets.dart';
import '../data/discover_data.dart';
import 'discover_widgets.dart';

/// Tag of the [i]th product of a ranking.
String? rankBadge(ProductRanking r, HomeProduct p, int i) {
  // The top 3 keep just the rank so the tag fits a 360 card.
  if (i < 3) return '#${i + 1}';
  if (r == ProductRanking.bestSelling && p.sold > 0) {
    return 'انباع ${compactCount(p.sold)}';
  }
  return null;
}

/// Home slider of a ranking: the first 10 and «عرض المزيد».
class RankingSlider extends ConsumerWidget {
  const RankingSlider({super.key, required this.ranking});
  final ProductRanking ranking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strip = ref.watch(rankingStripProvider(ranking));
    final list = strip.value;
    if (list != null && list.isEmpty) return const SizedBox.shrink();
    if (strip.hasError && list == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          ranking.title,
          seeAllLabel: 'عرض المزيد',
          onSeeAll: () => context.push(Routes.ranking(ranking.path)),
        ),
        if (list == null)
          LayoutBuilder(
            builder: (context, box) {
              final w = ProductStrip.cardWidthFor(box.maxWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 20),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: ProductStrip.gap),
                      SizedBox(width: w, child: const ProductCardSkeleton()),
                    ],
                  ],
                ),
              );
            },
          )
        else
          ProductStrip(
            products: list,
            badges: [
              for (var i = 0; i < list.length; i++)
                rankBadge(ranking, list[i], i),
            ],
          ),
      ],
    );
  }
}

/// «عرض المزيد»: the whole ranking, paged with infinite scroll.
class RankedProductsScreen extends ConsumerWidget {
  const RankedProductsScreen({super.key, required this.ranking});
  final ProductRanking ranking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = rankedProductsProvider(ranking);
    final s = ref.watch(provider);
    final cart = ref.watch(cartSummaryProvider);
    final notifier = ref.read(provider.notifier);
    return LoadMoreListener(
      onLoadMore: notifier.loadMore,
      child: AppPage(
        title: ranking.title,
        subtitle: ranking.subtitle,
        onRefresh: notifier.reload,
        bottom: cart.isEmpty
            ? null
            : StoreWidth(
                top: 0,
                padded: false,
                maxWidth: 760,
                child: CartBar(
                  cart: cart,
                  onTap: () => context.push(Routes.cart),
                ),
              ),
        children: [
          StoreWidth(
            child: s.firstLoad
                ? const ProductGrid(items: [], skeleton: 6)
                : s.error != null && s.items.isEmpty
                ? StoreMessage(
                    icon: AppIcon.wifiOff,
                    title: 'ما قدرنا نجيب المنتجات',
                    body: 'تأكد من النت وجرّب مرة ثانية.',
                    onRetry: notifier.reload,
                  )
                : s.empty
                ? const StoreMessage(
                    title: 'ماكو منتجات حالياً',
                    body:
                        'أول ما الصفحات تبيع وتنقيّم منتجاتها راح تشوفها هنا.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('${s.total} منتج', style: AppText.muted),
                      ),
                      ProductGrid(
                        items: [
                          for (var i = 0; i < s.items.length; i++)
                            homeProductCard(
                              s.items[i],
                              badge: rankBadge(ranking, s.items[i], i),
                            ),
                        ],
                      ),
                      LoadMoreFooter(
                        loading: s.loading,
                        done: s.done,
                        failed: s.error != null,
                        onRetry: notifier.loadMore,
                        endText: 'شفت كل المنتجات',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
