import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/catalog.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/app_page.dart';
import '../../guest/guest.dart';
import '../../home/presentation/widgets/home_sections.dart';
import '../../store/presentation/widgets/store_widgets.dart';
import '../data/discover_data.dart';

/// «1250» → «1.2 ألف»; small numbers stay as they are.
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1).replaceAll('.0', '')} ألف';
  }
  final m = n / 1000000;
  return '${m.toStringAsFixed(1).replaceAll('.0', '')} مليون';
}

/// Round page avatar: the page image, or its first letter.
class PageAvatar extends StatelessWidget {
  const PageAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 56,
    this.ring = false,
  });
  final String name;
  final String? image;
  final double size;

  /// Gold story-style ring (featured pages, profile header).
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final img = image ?? '';
    final inner = ClipOval(
      child: img.isEmpty
          ? Container(
              color: AppColors.blueTint,
              alignment: Alignment.center,
              child: Text(
                name.characters.firstOrNull ?? '',
                style: TextStyle(
                  fontSize: size * .4,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            )
          : AppImage(img, width: size, height: size, fit: BoxFit.cover),
    );
    if (!ring) return SizedBox.square(dimension: size, child: inner);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.gold, Color(0xFFF6D27A), AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        child: inner,
      ),
    );
  }
}

/// «تابع» / «تتابعه» with an optimistic update shared across screens.
class FollowButton extends ConsumerWidget {
  const FollowButton({
    super.key,
    required this.pageId,
    required this.following,
    required this.followers,
    this.compact = false,
    this.expand = false,
  });
  final String pageId;

  /// What the server last sent; session changes win over it.
  final bool following;
  final int followers;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref
        .watch(followProvider.notifier)
        .resolve(pageId, following, followers);
    ref.watch(followProvider);
    final on = s.following;
    final fg = on ? AppColors.ink : AppColors.white;
    final label = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(
          on ? AppIcon.check : AppIcon.userPlus,
          color: fg,
          size: compact ? 15 : 17,
          strokeWidth: 2.2,
        ),
        const SizedBox(width: 6),
        Text(
          on ? 'تتابعه' : 'تابع',
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      toggled: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => memberOnly(context, ref, () async {
          try {
            await ref.read(followProvider.notifier).toggle(pageId, s);
          } catch (e) {
            if (context.mounted) showAppToast(context, storeError(e));
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: on ? AppColors.surface : AppColors.blue,
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: on ? AppColors.border : AppColors.blue,
              width: 1.5,
            ),
          ),
          child: label,
        ),
      ),
    );
  }
}

/// Followers count that follows the session follow state.
int followersOf(WidgetRef ref, String pageId, bool following, int followers) {
  ref.watch(followProvider);
  return ref
      .read(followProvider.notifier)
      .resolve(pageId, following, followers)
      .followers;
}

/// «الصفحات المميزة»: the top 5 as boxes of one fixed size.
class TopPagesBoxes extends ConsumerWidget {
  const TopPagesBoxes({super.key});

  static const boxWidth = 128.0;
  static const boxHeight = 178.0;
  static const gap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(topPagesProvider);
    final list = pages.value;
    if (pages.hasError && list == null) return const SizedBox.shrink();
    final count = list?.length ?? 5;
    if (count == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'الصفحات المميزة',
          onSeeAll: () => context.go(Routes.pages),
        ),
        SizedBox(
          height: boxHeight + 22,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 18),
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (context, i) => SizedBox(
              width: boxWidth,
              height: boxHeight,
              child: list == null
                  ? const _BoxShell(child: SizedBox.expand())
                  : _TopPageBox(page: list[i], rank: i + 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoxShell extends StatelessWidget {
  const _BoxShell({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.cardRing, spreadRadius: 1),
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    ),
  );
}

class _TopPageBox extends ConsumerWidget {
  const _TopPageBox({required this.page, required this.rank});
  final PageCard page;
  final int rank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = page;
    final followers = followersOf(ref, p.id, p.isFollowing, p.followerCount);
    return _BoxShell(
      onTap: () => context.push(Routes.pageProfile(p.id)),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 8,
            start: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: rank == 1 ? AppColors.gold : AppColors.goldSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$rank',
                style: AppText.number.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
            child: Column(
              children: [
                PageAvatar(name: p.name, image: p.image, size: 64, ring: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: 22,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.strong.copyWith(
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (p.trusted) ...[
                        const SizedBox(width: 3),
                        const AppSvgIcon(
                          AppIcon.verified,
                          color: AppColors.gold,
                          size: 14,
                          strokeWidth: 2.4,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppSvgIcon(
                        AppIcon.star,
                        color: AppColors.gold,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        p.rating.toStringAsFixed(1),
                        style: AppText.number.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' · ${p.productCount} منتج',
                        maxLines: 1,
                        style: AppText.muted.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${compactCount(followers)} متابع',
                    maxLines: 1,
                    style: AppText.label.copyWith(
                      fontSize: 11.5,
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
}

/// A premium page card in the «الصفحات» tab.
class PageDirectoryCard extends ConsumerWidget {
  const PageDirectoryCard({super.key, required this.page});
  final PageCard page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = page;
    final followers = followersOf(ref, p.id, p.isFollowing, p.followerCount);
    void open() => context.push(Routes.pageProfile(p.id));
    return GestureDetector(
      onTap: open,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.cardRing, spreadRadius: 1),
            BoxShadow(
              color: AppColors.navy.withValues(alpha: .06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PageAvatar(
                  name: p.name,
                  image: p.image,
                  size: 58,
                  ring: p.featuredOrder != null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              color: AppColors.gold,
                              size: 16,
                              strokeWidth: 2.4,
                            ),
                          ],
                          if (p.featuredOrder != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'مميزة',
                                style: AppText.label.copyWith(
                                  fontSize: 10.5,
                                  color: AppColors.warnText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const AppSvgIcon(
                            AppIcon.star,
                            color: AppColors.gold,
                            size: 13,
                          ),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: AppText.number.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '(${p.ratingCount}) · ${p.productCount} منتج ·',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                          Text(
                            '${compactCount(followers)} متابع',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FollowButton(
                  pageId: p.id,
                  following: p.isFollowing,
                  followers: p.followerCount,
                  compact: true,
                ),
              ],
            ),
            if (p.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                p.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 13, height: 1.6),
              ),
            ],
            if (p.categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in p.categories.take(3))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CategoryIcon(
                            ref.watch(catalogProvider).value?.slugOf(c),
                            size: 13,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c,
                            style: AppText.label.copyWith(
                              fontSize: 11.5,
                              color: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (p.previews.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) {
                  const gap = 8.0;
                  final n = box.maxWidth >= 520 ? 4 : 3;
                  final side = (box.maxWidth - gap * (n - 1)) / n;
                  return Row(
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: side,
                            height: side * .8,
                            color: AppColors.sand,
                            child: i < p.previews.length
                                ? AppImage(
                                    p.previews[i],
                                    width: side,
                                    height: side * .8,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps a scrollable and asks for the next page near the end.
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.onLoadMore,
    required this.child,
  });
  final VoidCallback onLoadMore;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) {
            onLoadMore();
          }
          return false;
        },
        child: child,
      );
}

/// Footer of an infinite list: spinner, retry, or the end.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.loading,
    required this.done,
    required this.failed,
    required this.onRetry,
    this.endText = 'هذا كلشي',
  });
  final bool loading;
  final bool done;
  final bool failed;
  final VoidCallback onRetry;
  final String endText;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: loading
          ? SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.blue,
              ),
            )
          : failed
          ? TextButton(
              onPressed: onRetry,
              child: const Text('ما انحمّل الباقي، جرّب مرة ثانية'),
            )
          : done
          ? Text(endText, style: AppText.muted.copyWith(fontSize: 12.5))
          : const SizedBox(height: 26),
    ),
  );
}

/// A small «empty» note used where a whole StoreMessage is too much.
Widget quietNote(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 24),
  child: Center(child: Text(text, style: AppText.muted)),
);
