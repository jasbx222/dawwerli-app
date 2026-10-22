import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_image.dart';

/// What a [ProductCard] shows. Built from a page product or a home product.
class ProductCardData {
  const ProductCardData({
    required this.id,
    required this.pageId,
    required this.name,
    required this.price,
    this.description = '',
    this.image = '',
    this.available = true,
    this.stock,
    this.caption,
    this.badge,
    this.badgeIcon,
    this.rating = 0,
    this.ratingCount = 0,
    this.captionRating,
  });
  final String id;
  final String pageId;
  final String name;
  final String description;
  final int price;
  final String image;
  final bool available;
  final int? stock;

  /// Small line above the title, e.g. the page name on home.
  final String? caption;

  /// Corner tag on the image, e.g. the page rating or «باقي 2».
  final String? badge;
  final AppIcon? badgeIcon;

  /// Product rating; the chip shows only once someone rated it.
  final double rating;
  final int ratingCount;

  /// Star value shown after [caption], e.g. the page rating on home.
  final double? captionRating;
}

/// Where the add-to-cart action sits.
enum ProductCardCta {
  /// «أضف» pill next to the price. Needs ~190px of width.
  pill,

  /// Compact rounded cart button in the bottom corner. Fits 2-column grids.
  corner,
}

/// Store product card: big rounded image, corner badge, favorite heart, bold
/// title, two muted description lines and the price with the cart action.
///
/// Uses directional insets, so the badge and the heart swap sides in RTL.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.data,
    this.onTap,
    this.onAdd,
    this.favorite = false,
    this.onFavorite,
    this.cta = ProductCardCta.corner,
    this.width,
    this.adding = false,
  });

  final ProductCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final bool favorite;
  final VoidCallback? onFavorite;
  final ProductCardCta cta;
  final double? width;

  /// Shows a spinner on the cart action while the add request runs.
  final bool adding;

  static const radius = 26.0;
  static const imageRadius = 20.0;
  static const inset = 7.0;
  static const soldOut = 'نفدت الكمية';
  static const addLabel = 'أضف';

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      button: onTap != null,
      label:
          '${data.name}، ${thousands(data.price)} دينار'
          '${data.available ? '' : '، $soldOut'}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(inset),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardRing),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: .07),
                offset: const Offset(0, 10),
                blurRadius: 24,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImageArea(
                data: data,
                favorite: favorite,
                onFavorite: onFavorite,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(7, 10, 7, 3),
                child: _Texts(data: data),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(7, 8, 0, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _Price(data: data)),
                    const SizedBox(width: 6),
                    _Cta(
                      cta: cta,
                      available: data.available,
                      adding: adding,
                      onAdd: onAdd,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({
    required this.data,
    required this.favorite,
    required this.onFavorite,
  });
  final ProductCardData data;
  final bool favorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(ProductCard.imageRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.blueTint,
            child: data.image.isEmpty
                ? Center(
                    child: AppSvgIcon(
                      AppIcon.bag,
                      size: 40,
                      color: AppColors.blue.withValues(alpha: .35),
                    ),
                  )
                : AppImage(data.image, fit: BoxFit.cover),
          ),
          if (!data.available)
            ColoredBox(
              color: AppColors.navy.withValues(alpha: .45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    ProductCard.soldOut,
                    style: AppText.label.copyWith(
                      color: AppColors.navy,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          if (data.badge != null && data.available)
            PositionedDirectional(
              top: 9,
              start: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.badgeIcon != null) ...[
                      AppSvgIcon(
                        data.badgeIcon!,
                        size: 12,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      data.badge!,
                      style: AppText.label.copyWith(
                        color: AppColors.navy,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (data.ratingCount > 0 && data.available)
            PositionedDirectional(
              bottom: 8,
              start: 8,
              child: RatingChip(rating: data.rating, count: data.ratingCount),
            ),
          if (onFavorite != null)
            PositionedDirectional(
              top: 7,
              end: 7,
              child: FavoriteButton(on: favorite, onTap: onFavorite!),
            ),
        ],
      ),
    ),
  );
}

/// White round heart button used on cards and the product gallery.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.on,
    required this.onTap,
    this.size = 32,
  });
  final bool on;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: on,
    label: on ? 'شيل من المفضلة' : 'أضف للمفضلة',
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: AppSvgIcon(
            on ? AppIcon.heartFilled : AppIcon.heart,
            key: ValueKey(on),
            size: size * .52,
            color: on ? AppColors.danger : AppColors.navy,
          ),
        ),
      ),
    ),
  );
}

class _Texts extends StatelessWidget {
  const _Texts({required this.data});
  final ProductCardData data;

  @override
  Widget build(BuildContext context) {
    final desc = TextStyle(
      fontFamily: AppText.family,
      fontSize: 12.5,
      height: 1.5,
      color: AppColors.grey,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.caption != null && data.caption!.isNotEmpty)
          Row(
            children: [
              Flexible(
                child: Text(
                  data.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(
                    fontSize: 11.5,
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if ((data.captionRating ?? 0) > 0) ...[
                const SizedBox(width: 4),
                const AppSvgIcon(AppIcon.star, size: 11, color: AppColors.gold),
                const SizedBox(width: 2),
                Text(
                  data.captionRating!.toStringAsFixed(1),
                  style: AppText.label.copyWith(
                    fontSize: 11,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        Text(
          data.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.strong.copyWith(fontSize: 15.5, height: 1.45),
        ),
        const SizedBox(height: 2),
        // Always two lines tall so cards in a row line up.
        Stack(
          children: [
            ExcludeSemantics(
              child: Opacity(opacity: 0, child: Text(' \n ', style: desc)),
            ),
            Text(
              data.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: desc,
            ),
          ],
        ),
      ],
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.data});
  final ProductCardData data;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text.rich(
      TextSpan(
        text: thousands(data.price),
        style: AppText.number.copyWith(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: data.available ? AppColors.ink : AppColors.grey,
        ),
        children: [
          TextSpan(
            text: ' د.ع',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Cta extends StatelessWidget {
  const _Cta({
    required this.cta,
    required this.available,
    required this.adding,
    required this.onAdd,
  });
  final ProductCardCta cta;
  final bool available;
  final bool adding;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (onAdd == null && available) return const SizedBox.shrink();
    final bg = available ? AppColors.gold : AppColors.disabledBg;
    final fg = available ? AppColors.navy : AppColors.disabledText;
    final icon = adding
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : AppSvgIcon(AppIcon.cart, size: 18, color: fg);
    final child = switch (cta) {
      ProductCardCta.pill => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              available ? ProductCard.addLabel : 'نفدت',
              style: AppText.label.copyWith(color: fg, fontSize: 13),
            ),
          ],
        ),
      ),
      ProductCardCta.corner => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: icon,
      ),
    };
    return Semantics(
      button: true,
      enabled: available,
      label: available ? 'أضف للسلة' : ProductCard.soldOut,
      child: GestureDetector(
        onTap: available && !adding ? onAdd : null,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}

/// Grey placeholder with the card's shape while products load.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key, this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    final card = Container(
      padding: const EdgeInsets.all(ProductCard.inset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ProductCard.radius),
        border: Border.all(color: AppColors.cardRing),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.tabTrack,
                borderRadius: BorderRadius.circular(ProductCard.imageRadius),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 12, 7, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(110, 14),
                const SizedBox(height: 8),
                bar(double.infinity, 10),
                const SizedBox(height: 6),
                bar(70, 10),
                const SizedBox(height: 14),
                bar(60, 16),
              ],
            ),
          ),
        ],
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}

/// White pill with a gold SVG star, the average and the count: «★ 4.5 (12)».
class RatingChip extends StatelessWidget {
  const RatingChip({super.key, required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'التقييم ${rating.toStringAsFixed(1)} من 5، $count تقييم',
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvgIcon(AppIcon.star, size: 12, color: AppColors.gold),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: AppText.label.copyWith(
                color: AppColors.navy,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '($count)',
              style: AppText.label.copyWith(
                color: const Color(0xFF5B6478),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Five SVG stars, filled up to [value] (rounded to the nearest whole star).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, this.size = 16});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: AppSvgIcon(
            i <= value.round() ? AppIcon.star : AppIcon.starOutline,
            size: size,
            color: AppColors.gold,
            strokeWidth: 1.8,
          ),
        ),
    ],
  );
}
