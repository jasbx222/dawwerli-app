import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/home_models.dart';

/// Home «صفحات موثّقة» card: navy gradient, gold badge, real count from
/// `/api/v1/home` → `stats`, avatars of verified pages already on home.
class VerifiedPagesCard extends StatelessWidget {
  const VerifiedPagesCard({
    super.key,
    required this.count,
    required this.pages,
    required this.onTap,
    this.governorates,
    this.avgFirstOfferMinutes,
  });

  final int count;

  /// Up to three page logos for the overlapping avatars.
  final List<ImageRef> pages;
  final int? governorates;
  final int? avgFirstOfferMinutes;
  final VoidCallback onTap;

  String get _sub => [
    AppStrings.verifiedAllChecked,
    if (governorates != null) AppStrings.inGovernorates(governorates!),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final night = AppColors.dark;
    final rest = count - pages.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: night
                    ? const [Color(0xFF1B2D57), AppColors.brandBlue]
                    : const [AppColors.navy, AppColors.brandBlue],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: night ? 0.45 : 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: night ? 0.5 : 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Small decorative watermark, fully inside the card.
                PositionedDirectional(
                  end: 14,
                  top: 12,
                  child: AppSvgIcon(
                    AppIcon.verified,
                    size: 44,
                    strokeWidth: 1.4,
                    color: AppColors.goldSoft.withValues(alpha: 0.14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _GoldBadge(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      thousands(count),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        AppStrings.verifiedPagesLabel(count),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.goldSoft,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _sub,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: AppColors.headerSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Room for the watermark.
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Avatars(
                            pages: pages,
                            rest: rest,
                            size: 30,
                            ring: night
                                ? const Color(0xFF1C3A72)
                                : const Color(0xFF173468),
                          ),
                          if (avgFirstOfferMinutes != null) ...[
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                AppStrings.firstOfferIn(avgFirstOfferMinutes!),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.headerSub,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          SeeThemButton(onTap: onTap),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [AppColors.goldSoft, AppColors.gold],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.35),
          blurRadius: 12,
        ),
      ],
    ),
    child: Center(
      child: AppSvgIcon(AppIcon.verified, size: 26, color: AppColors.navy),
    ),
  );
}

/// Gold pill «شوفها ‹» with a soft shadow; shrinks and deepens when pressed.
class SeeThemButton extends StatefulWidget {
  const SeeThemButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<SeeThemButton> createState() => _SeeThemButtonState();
}

class _SeeThemButtonState extends State<SeeThemButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.verifiedSeeThem,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            padding: const EdgeInsetsDirectional.fromSTEB(18, 9, 14, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _down
                    ? const [AppColors.gold, Color(0xFFD29C1F)]
                    : const [AppColors.goldSoft, AppColors.gold],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: _down ? 0.18 : 0.38),
                  blurRadius: _down ? 6 : 14,
                  offset: Offset(0, _down ? 2 : 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.verifiedSeeThem,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 6),
                // Forward in RTL points left; flip for LTR.
                Directionality.of(context) == TextDirection.rtl
                    ? AppSvgIcon(
                        AppIcon.chevronLeft,
                        size: 15,
                        strokeWidth: 2.6,
                        color: AppColors.navy,
                      )
                    : Transform.flip(
                        flipX: true,
                        child: AppSvgIcon(
                          AppIcon.chevronLeft,
                          size: 15,
                          strokeWidth: 2.6,
                          color: AppColors.navy,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping page logos, plus a «+N» bubble for the rest.
class _Avatars extends StatelessWidget {
  const _Avatars({
    required this.pages,
    required this.rest,
    required this.size,
    required this.ring,
  });
  final List<ImageRef> pages;
  final int rest;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final p in pages)
        Container(
          color: AppColors.white,
          child: AppImage(p, width: size, height: size, fit: BoxFit.cover),
        ),
      if (rest > 0)
        Container(
          color: AppColors.white.withValues(alpha: 0.14),
          alignment: Alignment.center,
          child: Text(
            '+${thousands(rest)}',
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final step = size * 0.68;
    final outer = size + 4;
    return SizedBox(
      width: outer + step * (items.length - 1),
      height: outer,
      child: Stack(
        children: [
          for (var i = 0; i < items.length; i++)
            PositionedDirectional(
              start: step * i,
              child: Container(
                width: outer,
                height: outer,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
                child: ClipOval(child: items[i]),
              ),
            ),
        ],
      ),
    );
  }
}
