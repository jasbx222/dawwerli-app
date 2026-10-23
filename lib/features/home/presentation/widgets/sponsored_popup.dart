import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/sponsored_popup_ad.dart';

/// What the customer tapped in the popup.
enum PopupAction { offer, page }

abstract final class _Text {
  static const sponsored = 'إعلان ممول';
  static const close = 'سكّر الإعلان';
  static const seeOffer = 'شوف العرض';
  static const visitPage = 'زور الصفحة';
  static String discount(int p) => 'خصم $p٪';
}

/// Shows [ad] over the current screen for [duration], then closes by itself.
/// X, back and a tap outside close it at any time. Resolves to the tapped
/// action, or null when it was closed. [onSeen] fires once the popup has
/// been visible for [seenAfter] (the impression rule).
Future<PopupAction?> showSponsoredPopup(
  BuildContext context, {
  required SponsoredPopupAd ad,
  required Duration duration,
  VoidCallback? onSeen,
  Duration seenAfter = const Duration(seconds: 1),
}) => showGeneralDialog<PopupAction>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: true,
  barrierLabel: _Text.close,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, _, _) => SponsoredPopup(
    ad: ad,
    duration: duration,
    onSeen: onSeen,
    seenAfter: seenAfter,
  ),
  transitionBuilder: (_, anim, _, child) {
    final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: .92, end: 1.0).animate(curve),
        child: child,
      ),
    );
  },
);

/// The sponsored popup card. Closes itself via the nearest navigator.
class SponsoredPopup extends StatefulWidget {
  const SponsoredPopup({
    super.key,
    required this.ad,
    required this.duration,
    this.onSeen,
    this.seenAfter = const Duration(seconds: 1),
    this.frozenAt,
  });
  final SponsoredPopupAd ad;
  final Duration duration;
  final VoidCallback? onSeen;
  final Duration seenAfter;

  /// Fixed progress (0..1) for previews: no timers or auto-close; X still
  /// closes the preview dialog.
  final double? frozenAt;

  @override
  State<SponsoredPopup> createState() => _SponsoredPopupState();
}

class _SponsoredPopupState extends State<SponsoredPopup>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _seen;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    if (widget.frozenAt case final f?) {
      _progress.value = f;
      return;
    }
    _progress.forward().whenComplete(() {
      if (_progress.isCompleted) _close(null);
    });
    if (widget.onSeen case final seen?) {
      _seen = Timer(widget.seenAfter, () {
        if (mounted && !_closed) seen();
      });
    }
  }

  void _close(PopupAction? action) {
    if (_closed || !mounted) return;
    _closed = true;
    _seen?.cancel();
    _progress.stop();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) Navigator.of(context).pop(action);
  }

  @override
  void dispose() {
    _seen?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark || AppColors.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: _Text.close,
            child: GestureDetector(
              onTap: () => _close(null),
              behavior: HitTestBehavior.opaque,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: ColoredBox(
                  color: AppColors.navy.withValues(alpha: dark ? .78 : .62),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(child: _card(widget.ad, dark)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(SponsoredPopupAd ad, bool dark) => Container(
    constraints: const BoxConstraints(maxWidth: 360),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: AppColors.gold.withValues(alpha: dark ? .55 : .9),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .35),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _progressBar(),
        SizedBox(
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(ad.image, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navy.withValues(alpha: .35),
                      Colors.transparent,
                      AppColors.navy.withValues(alpha: .85),
                    ],
                    stops: const [0, .35, 1],
                  ),
                ),
              ),
              PositionedDirectional(top: 14, start: 14, child: _chip()),
              PositionedDirectional(top: 8, end: 8, child: _closeButton()),
              if (ad.discountPercent > 0)
                PositionedDirectional(
                  bottom: 16,
                  end: 16,
                  child: Transform.rotate(
                    angle: -.08,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.turquoise,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _Text.discount(ad.discountPercent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              if (ad.title.isNotEmpty)
                PositionedDirectional(
                  start: 16,
                  bottom: 14,
                  end: ad.discountPercent > 0 ? 110 : 16,
                  child: Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _avatar(ad),
                  const SizedBox(width: 10),
                  Expanded(child: _pageInfo(ad)),
                ],
              ),
              if (ad.headline.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  ad.headline,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: .85),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 3, child: _primary()),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _secondary(dark)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Thin bar that shrinks over the display time. The only countdown cue.
  Widget _progressBar() => AnimatedBuilder(
    animation: _progress,
    builder: (_, _) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: 1 - _progress.value,
        child: Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.goldSoft, AppColors.gold],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _pageInfo(SponsoredPopupAd ad) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Flexible(
            child: Text(
              ad.pageName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (ad.pageVerified) ...[
            const SizedBox(width: 4),
            const AppSvgIcon(
              AppIcon.verified,
              color: AppColors.blueLight,
              size: 17,
            ),
          ],
        ],
      ),
      if (ad.pageHandle.isNotEmpty)
        Text(
          // LTR isolate keeps «@handle» readable inside Arabic text.
          '\u2066@${ad.pageHandle.replaceFirst('@', '')}\u2069',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.grey, fontSize: 12.5),
        ),
    ],
  );

  Widget _chip() => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.goldSoft.withValues(alpha: .7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(AppIcon.sparkles, color: AppColors.goldSoft, size: 14),
            SizedBox(width: 5),
            Text(
              _Text.sponsored,
              style: TextStyle(
                color: AppColors.goldSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// Plain close button, tappable from the first moment (48px target).
  Widget _closeButton() => Semantics(
    button: true,
    label: _Text.close,
    child: GestureDetector(
      key: const ValueKey('sponsored-popup-close'),
      onTap: () => _close(null),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navy.withValues(alpha: .6),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: const AppSvgIcon(
              AppIcon.x,
              color: Colors.white,
              size: 18,
              strokeWidth: 2.6,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _avatar(SponsoredPopupAd ad) => Container(
    width: 46,
    height: 46,
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [AppColors.goldSoft, AppColors.gold]),
    ),
    child: ClipOval(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.brandBlue],
          ),
        ),
        alignment: Alignment.center,
        child: ad.pageImage.isNotEmpty
            ? AppImage(ad.pageImage, fit: BoxFit.cover, width: 42, height: 42)
            : Text(
                initialOf(ad.pageName),
                style: const TextStyle(
                  color: AppColors.goldSoft,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
      ),
    ),
  );

  Widget _primary() => GestureDetector(
    key: const ValueKey('sponsored-popup-offer'),
    onTap: () => _close(PopupAction.offer),
    child: Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.brandBlue, AppColors.blueLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueLight.withValues(alpha: .35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _Text.seeOffer,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 6),
          AppSvgIcon(AppIcon.chevronLeft, color: Colors.white, size: 18),
        ],
      ),
    ),
  );

  Widget _secondary(bool dark) => GestureDetector(
    key: const ValueKey('sponsored-popup-page'),
    onTap: () => _close(PopupAction.page),
    child: Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.blueTint,
        border: Border.all(color: AppColors.blueRing),
      ),
      child: Text(
        _Text.visitPage,
        style: TextStyle(
          color: dark ? AppColors.ink : AppColors.blue,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// First letter of a page name, skipping «مركز» and «ال».
String initialOf(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  var word = words.length > 1 && words.first == 'مركز' ? words[1] : words.first;
  if (word.startsWith('ال') && word.length > 2) word = word.substring(2);
  return word.isEmpty ? '' : word.characters.first;
}
