import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Category key (API `slug`) → Tabler outline icon bundled under
/// `assets/icons/categories/` (MIT, see LICENSE-tabler-icons.txt).
const categoryIconFiles = <String, String>{
  'phones': 'device-mobile',
  'electronics': 'headphones',
  'clothing': 'shirt',
  'clothes': 'shirt',
  'shoes': 'shoe',
  'perfumes': 'perfume',
  'watches': 'device-watch',
  'beauty': 'sparkles',
  'care': 'brush',
  'home': 'home',
  'furniture': 'sofa',
  'appliances': 'wash-machine',
  'gaming': 'device-gamepad-2',
  'car-parts': 'engine',
  'kids': 'baby-carriage',
  'sports': 'ball-football',
  'books': 'book',
  'pharmacy': 'pill',
  'food': 'tools-kitchen-2',
  'gifts': 'gift',
  'pets': 'paw',
  'tools': 'tool',
};

/// Icon used for any key not in [categoryIconFiles].
const categoryFallbackIcon = 'category';

String _normalize(String key) =>
    key.trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '-');

/// Asset path for a category key; unknown or empty keys get the fallback.
String categoryIconAsset(String? key) {
  final file = categoryIconFiles[_normalize(key ?? '')] ?? categoryFallbackIcon;
  return 'assets/icons/categories/$file.svg';
}

/// Category line icon tinted with [color] (stroke uses `currentColor`).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(
    this.categoryKey, {
    super.key,
    this.size = 20,
    this.color = AppColors.blue,
  });

  /// Stable category key (the API `slug`), never the Arabic name.
  final String? categoryKey;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    categoryIconAsset(categoryKey),
    width: size,
    height: size,
    theme: SvgTheme(currentColor: color),
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}

/// Rounded tile with the icon on a soft tint (pickers, grids).
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile(
    this.categoryKey, {
    super.key,
    this.size = 40,
    this.color = AppColors.blue,
    this.background,
  });
  final String? categoryKey;
  final double size;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: CategoryIcon(categoryKey, size: size * .55, color: color),
  );
}
