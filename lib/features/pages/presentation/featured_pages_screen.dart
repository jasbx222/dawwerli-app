import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/page_tile.dart';
import '../../home/data/home_providers.dart';
import '../../home/domain/home_models.dart';
import '../domain/pages_repository.dart';

/// 45 — best pages for a category in the customer's governorate (paid «إعلان» first, then by rating).
class FeaturedPagesScreen extends ConsumerWidget {
  const FeaturedPagesScreen({
    super.key,
    this.query = const FeaturedQuery(categoryId: 'shoes', governorate: 'بغداد'),
  });

  final FeaturedQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(featuredPagesProvider(query));
    return Scaffold(
      body: data.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (f) => ListView(
          padding: EdgeInsets.zero,
          children: [
            AppHeader(
              title: AppStrings.featuredTitle(f.categoryName, f.governorate),
              subtitle: const Text(AppStrings.featuredSub),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            for (final p in f.pages)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _FeaturedCard(
                  page: p,
                  onTap: () => context.push(Routes.comingSoon),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              AppStrings.featuredFoot,
              textAlign: TextAlign.center,
              style: AppText.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.page, this.onTap});
  final PageSummary page;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.blueTint,
                image: page.image == null
                    ? null
                    : DecorationImage(
                        image: AssetImage(page.image!),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(page.name, style: AppText.strong),
                      const SizedBox(width: 4),
                      AppSvgIcon(
                        AppIcon.check,
                        color: AppColors.ink,
                        size: 14.7,
                        strokeWidth: 2.1,
                      ),
                    ],
                  ),
                  RatingLine(
                    text:
                        '${page.rating} · ${AppStrings.inAppDeals(page.deals)}',
                    fontSize: 12.5,
                  ),
                ],
              ),
            ),
            if (page.isAd) const AdPill(large: true),
          ],
        ),
      ),
    );
  }
}
