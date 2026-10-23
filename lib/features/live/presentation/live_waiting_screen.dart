import 'dart:ui' show ImageFilter;

import '../../../core/widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/order_redirect.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/state_card.dart';
import '../../home/data/home_notice.dart';
import '../../home/data/home_providers.dart';
import '../data/live_providers.dart';
import '../domain/live_request.dart';
import 'widgets/live_sheets.dart';
import 'widgets/offer_slots.dart';

enum _Sheet { none, cancel, widened }

/// 10 · Live request waiting for offers; 10b cancel sheet; 10c widened sheet.
class LiveWaitingScreen extends ConsumerStatefulWidget {
  const LiveWaitingScreen({
    super.key,
    required this.requestId,
    this.openCancel = false,
  });

  final String requestId;

  final bool openCancel;

  @override
  ConsumerState<LiveWaitingScreen> createState() => _LiveWaitingScreenState();
}

class _LiveWaitingScreenState extends ConsumerState<LiveWaitingScreen> {
  late _Sheet _sheet = widget.openCancel ? _Sheet.cancel : _Sheet.none;
  bool _widenedSeen = false;
  Future<void> _cancel() async {
    await ref.read(liveRepositoryProvider).cancel(widget.requestId);
    // Home re-reads the store: the cancelled request no longer shows as live.
    ref.invalidate(homeDataProvider);
    ref.read(homeNoticeProvider.notifier).show(AppStrings.cancelledBar);
    if (mounted) context.go(Routes.home);
  }

  /// Opens 08's price field prefilled with the suggested price; 08 saves it
  /// through the repository and pops back here.
  void _raise(LiveRequest r) {
    setState(() => _sheet = _Sheet.none);
    context.push(
      Uri(
        path: Routes.postDetails,
        queryParameters: {'editPrice': r.id, 'price': '${r.maxPrice}'},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveRequestProvider(widget.requestId));
    final r = live.value;
    if (r == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    if (r.storeOrderId != null) {
      return OrderRedirect(Routes.storeOrder(r.storeOrderId!));
    }
    // Show the widened notice once, as soon as the server reports it.
    if (r.widenedTo.isNotEmpty && !_widenedSeen && _sheet == _Sheet.none) {
      _widenedSeen = true;
      _sheet = _Sheet.widened;
    }
    final content = _Content(
      r: r,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
      onCompare: () => context.push(Routes.offers(r.id)),
      onCancel: () => setState(() => _sheet = _Sheet.cancel),
      onRepublish: () async {
        final id = await ref.read(liveRepositoryProvider).republish(r.id);
        ref.invalidate(homeDataProvider);
        if (context.mounted) context.go(Routes.liveRequest(id));
      },
      onRaise: () => _raise(r),
    );
    return PopScope(
      canPop: _sheet == _Sheet.none,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _sheet = _Sheet.none);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // CSS filter: blur(1px) behind the cancel sheet only (10b).
            if (_sheet == _Sheet.cancel)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: content,
              )
            else
              content,
            if (_sheet != _Sheet.none) ...[
              GestureDetector(
                onTap: () => setState(() => _sheet = _Sheet.none),
                child: const ColoredBox(color: Color(0x8C070E1F)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _sheet == _Sheet.cancel
                    ? CancelSheet(
                        onConfirm: _cancel,
                        onDismiss: () => setState(() => _sheet = _Sheet.none),
                      )
                    : WidenedSheet(
                        request: r,
                        onRaise: () => _raise(r),
                        onKeep: () => setState(() => _sheet = _Sheet.none),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.r,
    required this.onBack,
    required this.onCompare,
    required this.onCancel,
    required this.onRepublish,
    required this.onRaise,
  });

  final LiveRequest r;
  final VoidCallback onBack;
  final VoidCallback onCompare;
  final VoidCallback onCancel;
  final VoidCallback onRepublish;
  final VoidCallback onRaise;

  @override
  Widget build(BuildContext context) {
    final n = r.offerPrices.length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: AppStrings.liveTitle,
            onBack: onBack,
            below: _Summary(r: r),
          ),
          _m(14, _Stats(r: r)),
          if (r.expired)
            _m(
              14,
              StateCard(
                icon: AppIcon.clock,
                tint: AppColors.warnBg,
                tone: AppColors.warn,
                title: AppStrings.expiredTitle,
                body: TextSpan(
                  text: n > 0
                      ? AppStrings.expiredOffersBody(n)
                      : AppStrings.expiredBody,
                ),
              ),
            )
          else
            _m(
              14,
              OffersCard(
                offers: r.offerPrices,
                maxOffers: r.maxOffers,
                cheapest: r.cheapestIndex,
                // Countdown hidden once the request already widened (10c).
                widensAt: r.widenedTo.isEmpty ? r.widensAt : null,
              ),
            ),
          if (r.sponsored != null) _m(14, SponsoredCard(page: r.sponsored!)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: r.expired
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      n > 0
                          ? AppButton(
                              AppStrings.compareN(n),
                              variant: AppButtonVariant.navy,
                              onPressed: onCompare,
                            )
                          : AppButton(
                              AppStrings.republish,
                              onPressed: onRepublish,
                            ),
                      const SizedBox(height: 10),
                      AppButton(
                        AppStrings.raisePrice,
                        variant: AppButtonVariant.ghost,
                        onPressed: onRaise,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // CSS flex 2:1 splits the space left after the buttons' own
                      // padding, giving 222 / 126 in the design.
                      Expanded(
                        flex: 222,
                        child: AppButton(
                          AppStrings.compareN(n),
                          variant: n == 0
                              ? AppButtonVariant.disabled
                              : AppButtonVariant.navy,
                          onPressed: onCompare,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 126,
                        child: AppButton(
                          AppStrings.cancelIt,
                          variant: AppButtonVariant.ghost,
                          onPressed: onCancel,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _m(double top, Widget child) =>
      Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: child);
}

class _Summary extends StatelessWidget {
  const _Summary({required this.r});
  final LiveRequest r;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AppImage(
          r.image,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.title,
              style: AppText.strong.copyWith(
                color: AppColors.white,
                height: AppText.lh(14),
              ),
            ),
            Text(
              AppStrings.priceCap(thousands(r.maxPrice)),
              style: TextStyle(
                fontSize: 13,
                height: AppText.lh(13),
                color: AppColors.headerSub,
              ),
            ),
          ],
        ),
      ),
      // `.pill.pl-t` "● مباشر": the ● is drawn as a 5px dot (measured on the hi-res;
      // the glyph isn't in IBM Plex, so a text fallback renders it twice as large).
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: r.expired ? AppColors.tabTrack : AppColors.tealBg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!r.expired) ...[
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2.4),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              r.expired ? AppStrings.expiredPill : AppStrings.live,
              style: TextStyle(
                fontSize: 12,
                height: AppText.lh(12),
                fontWeight: FontWeight.w700,
                color: r.expired
                    ? AppColors.tabText
                    : AppColors.teal,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.r});
  final LiveRequest r;

  @override
  Widget build(BuildContext context) {
    // Column widths as laid out by the design's flex row (label-driven; Chrome's
    // Plex advance widths differ slightly from Flutter's, shifting space-around).
    Widget stat(String v, String label, double w) => SizedBox(
      width: w,
      child: Column(
        children: [
          Text(
            v,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: AppText.number.copyWith(
              fontSize: 22,
              height: AppText.lh(22),
              color: AppColors.blue,
            ),
          ),
          Text(
            label,
            style: AppText.muted,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
    // Column centres measured on the design render (from the content's left
    // edge); Chrome's space-around depends on its own glyph advances.
    Widget at(double cx, Widget c) => Positioned(
      left: cx - 60,
      width: 120,
      top: 0,
      child: Center(child: c),
    );
    return AppCard(
      child: SizedBox(
        height: AppText.lh(22) * 22 + AppText.lh(12.5) * 12.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            at(265.8, stat('${r.reachedPages}', AppStrings.statReached, 62.9)),
            at(149.3, stat('${r.seenBy}', AppStrings.statSeen, 29.6)),
            at(
              46.4,
              stat(
                '${r.offerPrices.length}/${r.maxOffers}',
                AppStrings.statOffers,
                36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
