import 'dart:typed_data';

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
    this.rating = 0,
    this.ratingCount = 0,
  });
  final String id;
  final String pageId;
  final String name;
  final String description;
  final int price;
  final String image;
  final bool available;
  final int? stock;

  /// Muted line under the title (e.g. the page name on home). Falls back to
  /// [description].
  final String? caption;

  /// The one tag on the image, e.g. «باقي 2». Sold out replaces it.
  final String? badge;

  /// Product rating; shown next to the muted line once someone rated it.
  final double rating;
  final int ratingCount;
}

/// Store product card in the reference's notched style: a rounded image, a
/// bold one-line title, one muted line, the price, and a single cart button
/// sitting in a notch cut out of the bottom-end corner.
///
/// Its height depends only on its width and the text scale (fixed line
/// counts, square image), so cards of the same width always line up. It has
/// no intrinsic width: give it one (grid cell, strip item).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.data,
    this.onTap,
    this.onAdd,
    this.favorite = false,
    this.onFavorite,
    this.adding = false,
  });

  final ProductCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final bool favorite;
  final VoidCallback? onFavorite;

  /// Shows a spinner on the cart button while the add request runs.
  final bool adding;

  static const radius = 22.0;
  static const imageRadius = 16.0;
  static const inset = 6.0;

  /// Cart button edge and the gap around it inside the notch.
  static const button = 44.0;
  static const notchGap = 6.0;
  static const notch = button + notchGap;
  static const soldOut = 'نفدت الكمية';

  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: AppColors.dark ? .3 : .07),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hasCta = onAdd != null || !data.available;
    return Semantics(
      container: true,
      label:
          '${data.name}، ${thousands(data.price)} دينار'
          '${data.available ? '' : '، $soldOut'}',
      child: Stack(
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(
              color: AppColors.surface,
              shadows: shadow,
              shape: NotchedCardBorder(notch: hasCta ? notch : 0),
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: NotchedCardBorder(notch: hasCta ? notch : 0),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        inset,
                        inset,
                        inset,
                        0,
                      ),
                      child: _ImageArea(
                        data: data,
                        favorite: favorite,
                        onFavorite: onFavorite,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        10,
                        12,
                        0,
                      ),
                      child: _Texts(data: data),
                    ),
                    SizedBox(
                      height: notch,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 12,
                          end: hasCta ? notch + 4 : 12,
                        ),
                        child: _Price(data: data),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasCta)
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: _CartButton(
                available: data.available,
                adding: adding,
                onAdd: onAdd,
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded card outline with a rounded notch cut from the bottom-end corner,
/// with soft fillets where the notch meets the card edges. Mirrors in RTL.
class NotchedCardBorder extends ShapeBorder {
  const NotchedCardBorder({
    this.radius = ProductCard.radius,
    this.notch = ProductCard.notch,
    this.fillet = 14,
    this.inner = 16,
  });
  final double radius;
  final double notch;
  final double fillet;
  final double inner;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final w = rect.width, h = rect.height;
    final r = radius.clamp(0.0, w / 2).clamp(0.0, h / 2);
    if (notch <= 0 || notch + fillet + r > w || notch + fillet + r > h) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    }
    final n = notch, f = fillet, c = inner;
    // Built for LTR (notch bottom-right), clockwise.
    final p = Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, h - n - f)
      ..arcToPoint(Offset(w - f, h - n), radius: Radius.circular(f))
      ..lineTo(w - n + c, h - n)
      ..arcToPoint(
        Offset(w - n, h - n + c),
        radius: Radius.circular(c),
        clockwise: false,
      )
      ..lineTo(w - n, h - f)
      ..arcToPoint(Offset(w - n - f, h), radius: Radius.circular(f))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
    final rtl = textDirection == TextDirection.rtl;
    final m = Float64List(16)
      ..[0] = rtl ? -1 : 1
      ..[5] = 1
      ..[10] = 1
      ..[15] = 1
      ..[12] = rect.left + (rtl ? w : 0)
      ..[13] = rect.top;
    return p.transform(m);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => NotchedCardBorder(
    radius: radius * t,
    notch: notch * t,
    fillet: fillet * t,
    inner: inner * t,
  );
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
  Widget build(BuildContext context) {
    final tag = !data.available ? ProductCard.soldOut : data.badge;
    return AspectRatio(
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
                        size: 36,
                        color: AppColors.blue.withValues(alpha: .3),
                      ),
                    )
                  : AppImage(data.image, fit: BoxFit.cover),
            ),
            if (!data.available)
              ColoredBox(color: AppColors.white.withValues(alpha: .45)),
            if (tag != null)
              PositionedDirectional(
                top: 8,
                start: 8,
                end: 46,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: _Tag(tag, soldOut: !data.available),
                ),
              ),
            if (onFavorite != null)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: FavoriteButton(on: favorite, onTap: onFavorite!),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.soldOut});
  final String text;
  final bool soldOut;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(
      color: soldOut ? AppColors.navy : AppColors.gold,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.label.copyWith(
        fontSize: 11,
        color: soldOut ? AppColors.white : AppColors.navy,
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
    this.size = 30,
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
    final line = (data.caption?.isNotEmpty ?? false)
        ? data.caption!
        : data.description;
    final muted = AppText.muted.copyWith(fontSize: 12.5, height: 1.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.strong.copyWith(fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 1),
        // Always one line tall, so every card has the same height.
        Row(
          children: [
            Expanded(
              child: Text(
                line.isEmpty ? ' ' : line.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
            if (data.ratingCount > 0) ...[
              const SizedBox(width: 6),
              const AppSvgIcon(AppIcon.star, size: 12, color: AppColors.gold),
              const SizedBox(width: 2),
              Text(
                data.rating.toStringAsFixed(1),
                style: muted.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(
          text: thousands(data.price),
          style: AppText.number.copyWith(
            fontSize: 16,
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
        maxLines: 1,
      ),
    ),
  );
}

/// The card's single add-to-cart action, sitting in the corner notch.
class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.available,
    required this.adding,
    required this.onAdd,
  });
  final bool available;
  final bool adding;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final fg = available ? AppColors.navy : AppColors.disabledText;
    return Semantics(
      button: true,
      enabled: available,
      label: available ? 'أضف للسلة' : ProductCard.soldOut,
      child: Material(
        color: available ? AppColors.gold : AppColors.disabledBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: available && !adding ? onAdd : null,
          child: SizedBox.square(
            dimension: ProductCard.button,
            child: Center(
              child: adding
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : AppSvgIcon(AppIcon.cart, size: 20, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder with the card's exact shape and height while products load.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, double h) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: AppColors.tabTrack,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
    final scale = MediaQuery.textScalerOf(context);
    return ExcludeSemantics(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(
              color: AppColors.surface,
              shadows: ProductCard.shadow,
              shape: const NotchedCardBorder(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ProductCard.inset,
                    ProductCard.inset,
                    ProductCard.inset,
                    0,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.tabTrack,
                        borderRadius: BorderRadius.circular(
                          ProductCard.imageRadius,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 0),
                  child: SizedBox(
                    height:
                        scale.scale(15) * 1.4 + 1 + scale.scale(12.5) * 1.45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [bar(.7, 12), bar(.45, 9)],
                    ),
                  ),
                ),
                SizedBox(
                  height: ProductCard.notch,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: ProductCard.notch + 4,
                    ),
                    child: Center(child: bar(.6, 14)),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Container(
              width: ProductCard.button,
              height: ProductCard.button,
              decoration: BoxDecoration(
                color: AppColors.tabTrack,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
