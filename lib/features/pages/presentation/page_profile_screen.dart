import 'package:flutter/material.dart';

import '../../../core/api/catalog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/seg_tabs.dart';
import '../../discover/data/discover_data.dart';
import '../../discover/presentation/discover_widgets.dart';
import '../../guest/guest.dart';
import '../../more/more_data.dart';
import '../../store/presentation/store_screens.dart';
import '../../store/presentation/widgets/store_widgets.dart';

/// Public page profile, Instagram style: avatar + stats, bio, follow,
/// then the products grid. No contact and no share on purpose.
class PageProfileScreen extends ConsumerStatefulWidget {
  const PageProfileScreen({super.key, required this.pageId});
  final String pageId;

  @override
  ConsumerState<PageProfileScreen> createState() => _PageProfileScreenState();
}

class _PageProfileScreenState extends ConsumerState<PageProfileScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pageProfileV2Provider(widget.pageId));
    final p = async.value;
    if (p == null) {
      return AppPage(
        title: '',
        children: [
          if (async.hasError)
            StoreMessage(
              icon: AppIcon.wifiOff,
              title: 'ما قدرنا نفتح الصفحة',
              body: 'تأكد من النت وجرّب مرة ثانية.',
              onRetry: () =>
                  ref.invalidate(pageProfileV2Provider(widget.pageId)),
            )
          else
            const _HeaderSkeleton(),
        ],
      );
    }
    final cart = ref.watch(cartSummaryProvider);
    final blocked = ref.watch(blockedProvider).contains(p.id);
    final onProducts = _tab == 0;
    return AppPage(
      title: p.name,
      titleIcon: p.trusted
          ? const AppSvgIcon(
              AppIcon.verified,
              color: AppColors.gold,
              size: 18,
              strokeWidth: 2.2,
            )
          : null,
      onRefresh: () async {
        ref.invalidate(pageProfileV2Provider(widget.pageId));
        ref.invalidate(pageProductsProvider(widget.pageId));
      },
      bottom: onProducts && !cart.isEmpty
          ? CartBar(cart: cart, onTap: () => context.push(Routes.cart))
          : null,
      children: [
        StoreWidth(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(p: p),
              const SizedBox(height: 16),
              SegTabs(
                labels: const ['المنتجات', 'عن الصفحة'],
                icons: const [AppIcon.grid, AppIcon.shieldCheck],
                selected: _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 14),
              if (onProducts)
                PageProductsSection(pageId: p.id)
              else
                _About(p: p, blocked: blocked),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.p});
  final PageProfileV2 p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followers = followersOf(ref, p.id, p.isFollowing, p.followerCount);
    final since = p.memberSince > 0 ? 'بالتطبيق من ${p.memberSince}' : null;
    final reach = p.governorates.isEmpty
        ? null
        : p.governorates.length <= 3
        ? 'توصّل لـ ${p.governorates.join('، ')}'
        : 'توصّل لـ ${p.governorates.take(3).join('، ')} و${p.governorates.length - 3} غيرها';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PageAvatar(name: p.name, image: p.image, size: 84, ring: true),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    _Stat(compactCount(p.productCount), 'منتجات'),
                    _Stat(
                      p.ratingCount == 0 ? '—' : p.rating.toStringAsFixed(1),
                      'تقييم',
                      star: p.ratingCount > 0,
                    ),
                    _Stat(compactCount(followers), 'متابعين'),
                    _Stat(compactCount(p.orderCount), 'طلبات'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.strong.copyWith(fontSize: 16),
                ),
              ),
              if (p.trusted) ...[
                const SizedBox(width: 4),
                const AppSvgIcon(
                  AppIcon.verified,
                  color: AppColors.blue,
                  size: 16,
                  strokeWidth: 2.2,
                ),
              ],
            ],
          ),
          if (p.categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                p.categories.join(' · '),
                style: AppText.muted.copyWith(fontSize: 12.5),
              ),
            ),
          if (p.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                p.bio,
                style: AppText.body.copyWith(fontSize: 13.5, height: 1.65),
              ),
            ),
          if (reach != null || since != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  if (reach != null) _Meta(AppIcon.pin, reach),
                  if (since != null) _Meta(AppIcon.clock, since),
                ],
              ),
            ),
          const SizedBox(height: 14),
          FollowButton(
            pageId: p.id,
            following: p.isFollowing,
            followers: p.followerCount,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.star = false});
  final String value;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppText.strong.copyWith(fontSize: 17)),
              if (star) ...[
                const SizedBox(width: 2),
                const AppSvgIcon(AppIcon.star, color: AppColors.gold, size: 13),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: AppText.muted.copyWith(fontSize: 12)),
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final AppIcon icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppSvgIcon(icon, color: AppColors.grey, size: 14),
      const SizedBox(width: 4),
      Flexible(child: Text(text, style: AppText.muted.copyWith(fontSize: 12))),
    ],
  );
}

class _About extends ConsumerWidget {
  const _About({required this.p, required this.blocked});
  final PageProfileV2 p;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (p.categories.isNotEmpty) ...[
        Text('شنو تبيع', style: AppText.strong.copyWith(fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in p.categories)
              AppChip(
                c,
                categoryKey: ref.watch(catalogProvider).value?.slugOf(c) ?? '',
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
      if (p.governorates.isNotEmpty) ...[
        Text('توصّل لـ', style: AppText.strong.copyWith(fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final g in p.governorates) AppChip(g)],
        ),
        const SizedBox(height: 16),
      ],
      AppCard(
        flat: true,
        color: AppColors.warnBg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSvgIcon(AppIcon.alert, color: AppColors.warn, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'افحص الغرض قدام المندوب قبل ما تدفع. الدفع عند الاستلام بس، لا تحوّل عربون.',
                style: AppText.body.copyWith(
                  fontSize: 13,
                  height: 1.7,
                  color: AppColors.warnText,
                ),
              ),
            ),
          ],
        ),
      ),
      if (blocked) ...[
        const SizedBox(height: 14),
        const AlertCard(
          title: 'هالصفحة محظورة',
          body: 'ما تشوف طلباتك ولا تكدر تقدّملك عروض.',
        ),
      ],
      const SizedBox(height: 14),
      AppButton(
        blocked ? 'الغي الحظر' : 'احظر هالصفحة',
        icon: AppIcon.lock,
        variant: AppButtonVariant.ghost,
        onPressed: () => memberOnly(context, ref, () {
          final n = ref.read(blockedProvider.notifier);
          if (blocked) {
            n.unblock(p.id);
            showAppToast(context, 'لغيت حظر ${p.name}');
          } else {
            n.block(p.id, name: p.name);
            showAppToast(context, 'حظرت ${p.name}، ما تشوف طلباتك بعد');
          }
        }),
      ),
    ],
  );
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) => StoreWidth(
    maxWidth: 760,
    child: Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        const ProductGrid(items: [], skeleton: 4),
      ],
    ),
  );
}
