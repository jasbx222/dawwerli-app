import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/notes.dart';
import '../../data/store_data.dart';
import 'product_card.dart';
import 'rating_sheet.dart';

/// «التقييمات والتعليقات» on product details: summary with 5→1 bars,
/// the customer's own rating (one per customer, editable), filter chips and
/// the review rows. Bars are computed from the latest 50 reviews.
class ProductReviewsSection extends ConsumerStatefulWidget {
  const ProductReviewsSection({
    super.key,
    required this.product,
    this.pageId = '',
  });
  final StoreProduct product;
  final String pageId;

  @override
  ConsumerState<ProductReviewsSection> createState() =>
      _ProductReviewsSectionState();
}

/// Filter keys: 0 = all, 1..5 = that many stars, -1 = with a comment.
class _ProductReviewsSectionState extends ConsumerState<ProductReviewsSection> {
  static const _withComment = -1;
  static const _preview = 5;
  var _filter = 0;
  var _expanded = false;

  StoreProduct get p => widget.product;

  void _rate() => showRateSheet(
    context,
    ref,
    productId: p.id,
    productName: p.name,
    pageId: widget.pageId,
  );

  @override
  Widget build(BuildContext context) {
    final reviews =
        ref.watch(productReviewsProvider(p.id)).value ??
        const <ProductReview>[];
    final mine = ref.watch(myRatingProvider(p.id)).value ?? MyRating.none;
    final myReview =
        p.myReview ??
        (mine.stars == null
            ? null
            : ProductReview(
                name: 'أنت',
                stars: mine.stars!,
                comment: mine.comment,
                at: null,
              ));
    final rated = p.hasRated || myReview != null;
    final counts = List<int>.filled(6, 0);
    for (final r in reviews) {
      if (r.stars >= 1 && r.stars <= 5) counts[r.stars]++;
    }
    final total = p.ratingCount > 0 ? p.ratingCount : reviews.length;
    final average = p.rating > 0
        ? p.rating
        : reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (a, r) => a + r.stars) / reviews.length;
    final commented = reviews.where((r) => r.comment.trim().isNotEmpty).length;
    final shown = [
      for (final r in reviews)
        if (_filter == 0 ||
            (_filter == _withComment && r.comment.trim().isNotEmpty) ||
            r.stars == _filter)
          r,
    ];
    final visible = _expanded ? shown : shown.take(_preview).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'التقييمات والتعليقات',
            style: AppText.strong.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (total == 0 && reviews.isEmpty)
            AppCard(
              padding: 14,
              child: Row(
                children: [
                  const AppSvgIcon(
                    AppIcon.starOutline,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'بعد ما أحد قيّم هالمنتج. إذا وصلك كون أول واحد يقيّمه.',
                      style: AppText.muted.copyWith(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            )
          else
            _Summary(average: average, total: total, counts: counts),
          const SizedBox(height: 12),
          if (rated && myReview != null)
            _MineCard(
              review: myReview,
              onEdit: mine.canRate || p.hasRated ? _rate : null,
            )
          else if (mine.canRate)
            AppButton(
              'قيّم المنتج واكتب تعليقك',
              icon: AppIcon.star,
              onPressed: _rate,
            )
          else
            AppCard(
              padding: 14,
              child: Row(
                children: [
                  const AppSvgIcon(
                    AppIcon.starOutline,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ما تكدر تقيّم هذا المنتج إلا بعد ما تطلبه ويوصلك.',
                      style: AppText.muted.copyWith(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _Chip(
                    'الكل · ${reviews.length}',
                    selected: _filter == 0,
                    onTap: () => _set(0),
                  ),
                  for (var s = 5; s >= 1; s--)
                    if (counts[s] > 0)
                      _Chip(
                        '$s',
                        star: true,
                        trailing: ' · ${counts[s]}',
                        selected: _filter == s,
                        onTap: () => _set(s),
                      ),
                  if (commented > 0)
                    _Chip(
                      'بتعليق · $commented',
                      selected: _filter == _withComment,
                      onTap: () => _set(_withComment),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'ماكو تقييمات بهالفلتر.',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
              ),
            for (var i = 0; i < visible.length; i++)
              _ReviewRow(review: visible[i], last: i == visible.length - 1),
            if (shown.length > _preview && !_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AppButton(
                  'شوف كل التقييمات (${shown.length})',
                  compact: true,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => setState(() => _expanded = true),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _set(int f) => setState(() {
    _filter = f;
    _expanded = false;
  });
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.average,
    required this.total,
    required this.counts,
  });
  final double average;
  final int total;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final sample = counts.fold<int>(0, (a, b) => a + b);
    return AppCard(
      padding: 16,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: AppText.number.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(child: StarRow(value: average, size: 14)),
                const SizedBox(height: 4),
                Text(
                  '$total تقييم',
                  style: AppText.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (var s = 5; s >= 1; s--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$s',
                            textAlign: TextAlign.center,
                            style: AppText.label.copyWith(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const AppSvgIcon(
                          AppIcon.star,
                          color: AppColors.gold,
                          size: 11,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              height: 8,
                              color: AppColors.border,
                              alignment: AlignmentDirectional.centerStart,
                              child: FractionallySizedBox(
                                widthFactor: sample == 0
                                    ? 0
                                    : counts[s] / sample,
                                heightFactor: 1,
                                child: Container(color: AppColors.gold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${counts[s]}',
                            textAlign: TextAlign.end,
                            style: AppText.muted.copyWith(fontSize: 11.5),
                          ),
                        ),
                      ],
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

class _MineCard extends StatelessWidget {
  const _MineCard({required this.review, this.onEdit});
  final ProductReview review;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: AppColors.blueTint,
    padding: 14,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AppSvgIcon(
              AppIcon.check,
              color: AppColors.blue,
              size: 18,
              strokeWidth: 2.4,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'قيّمت هذا المنتج',
                style: AppText.strong.copyWith(
                  fontSize: 14,
                  color: AppColors.blue,
                ),
              ),
            ),
            StarRow(value: review.stars.toDouble(), size: 14),
          ],
        ),
        if (review.comment.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '«${review.comment.trim()}»',
            style: AppText.body.copyWith(fontSize: 13.5, height: 1.7),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                review.at == null
                    ? 'تكدر تعدّل تقييمك بأي وقت'
                    : 'آخر تعديل ${agoLabel(review.at!)} · تكدر تعدّله بأي وقت',
                style: AppText.muted.copyWith(fontSize: 12),
              ),
            ),
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'عدّل تقييمك',
                    style: AppText.label.copyWith(
                      color: AppColors.blue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review, required this.last});
  final ProductReview review;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last ? null : Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LetterAvatar(review.name.isEmpty ? '؟' : review.name, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.name.isEmpty ? 'زبون' : review.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.strong.copyWith(fontSize: 13.5),
                    ),
                  ),
                  if (review.at != null)
                    Text(
                      agoLabel(review.at!),
                      style: AppText.muted.copyWith(fontSize: 11.5),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              StarRow(value: review.stars.toDouble(), size: 12),
              if (review.comment.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  review.comment.trim(),
                  style: AppText.body.copyWith(fontSize: 13.5, height: 1.7),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(
    this.label, {
    required this.selected,
    required this.onTap,
    this.star = false,
    this.trailing = '',
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool star;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.label.copyWith(fontSize: 12.5, color: fg),
              ),
              if (star) ...[
                const SizedBox(width: 3),
                AppSvgIcon(
                  AppIcon.star,
                  color: selected ? Colors.white : AppColors.gold,
                  size: 12,
                ),
              ],
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: AppText.label.copyWith(fontSize: 12.5, color: fg),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
