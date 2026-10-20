import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'app_icons.dart';

/// Flat tinted card with text (`.card` + background, no shadow): rules, receipts.
class TintedNote extends StatelessWidget {
  const TintedNote(
    this.text, {
    super.key,
    required this.bg,
    required this.fg,
    this.icon,
    this.title,
  });
  final String text;
  final String? title;
  final Color bg;
  final Color fg;
  final AppIcon? icon;

  static Color get blueBg => AppColors.blueTint;
  static const blueFg = Color(0xFF1F3B73);
  static const tealBg = Color(0xFFE6F7F5);
  static const tealFg = Color(0xFF0B6E66);

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: bg,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          AppSvgIcon(icon!, color: fg, size: AppSize.rowIcon),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(title!, style: AppText.strong.copyWith(color: fg)),
              Text(text, style: AppText.muted.copyWith(color: fg, height: 1.6)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Centered faded icon + title + body: empty lists.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final AppIcon icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        AppSvgIcon(
          icon,
          color: AppColors.navy.withValues(alpha: .3),
          size: AppSize.emptyIcon,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppText.strong),
        Text(body, style: AppText.muted, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
        const SizedBox(height: AppSpacing.sm),
      ],
    ),
  );
}

/// Big danger/success banner (18b, 24, 46): tinted card, square icon, title + body.
class BannerCard extends StatelessWidget {
  const BannerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.bg = AppColors.dangerBg,
    this.tile = const Color(0xFFB42318),
    this.fg = AppColors.dangerText,
  });
  final AppIcon icon;
  final String title;
  final String body;
  final Color bg;
  final Color tile;
  final Color fg;

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: bg,
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.fromLTRB(0, 4, 0, 10),
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(icon, color: AppColors.white, size: 30),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.strong.copyWith(fontSize: 18, color: fg),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: fg),
        ),
      ],
    ),
  );
}

/// Rounded photo square (`.th` 52×52, r16).
class Thumb extends StatelessWidget {
  const Thumb(
    this.image, {
    super.key,
    this.size = AppSize.thumb,
    this.radius = 16,
  });
  final String image;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(image, width: size, height: size, fit: BoxFit.cover),
  );
}

/// Letter avatar in a tinted rounded square.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar(this.name, {super.key, this.size = AppSize.iconTile});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.blueTint,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    alignment: Alignment.center,
    child: Text(
      name.characters.first,
      style: TextStyle(
        fontSize: size * .41,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: AppColors.blue,
      ),
    ),
  );
}

/// Centered big number + muted label (stats rows on 21c, 23, page profile).
class StatTile extends StatelessWidget {
  const StatTile(this.value, this.label, {super.key, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppText.big.copyWith(color: color ?? AppColors.ink)),
      Text(label, style: AppText.muted),
    ],
  );
}
