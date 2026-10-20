import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/offer_strings.dart';
import '../../../core/router/routes.dart';
import '../../states/state_screens.dart';
import '../../post/presentation/widgets/post_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../live/presentation/widgets/live_sheets.dart';
import '../data/offers_providers.dart';
import '../domain/offer.dart';
import 'widgets/offer_widgets.dart';

/// 11 · Compare offers; 13 · confirm-choice sheet over the list.
class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({
    super.key,
    required this.requestId,
    this.confirmId,
    this.forceError = false,
    this.hidden = const {},
  });

  /// 47 · offers hidden by the customer (`?preview=hidden` hides o3).
  final Set<String> hidden;

  /// `?preview=error` shows 34.
  final bool forceError;

  final String requestId;

  /// Opens the 13 sheet for this offer (from 12 «أريده» or `?preview=confirm`).
  final String? confirmId;

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  OfferSort _sort = OfferSort.cheapest;
  late String? _confirm = widget.confirmId;
  bool _busy = false;
  late final Set<String> _hidden = {...widget.hidden};
  bool _onlyHidden = false;
  String? _toast;
  bool _previewToastDone = false;

  // 47 · long-press a card to hide it; the toast explains it can come back.
  void _hide(Offer o) {
    setState(() {
      _hidden.add(o.id);
      _toast = OfferStrings.hiddenToast(o.pageName);
    });
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _back() => context.canPop()
      ? context.pop()
      : context.go(Routes.liveRequest(widget.requestId));

  Future<void> _open(Offer o) async {
    final want = await context.push<bool>(
      Routes.offerDetails(widget.requestId, o.id),
    );
    if (want == true && mounted) setState(() => _confirm = o.id);
  }

  Future<void> _select(Offer o) async {
    if (_busy) return;
    _busy = true;
    try {
      await ref.read(offersRepositoryProvider).select(widget.requestId, o.id);
    } on SelectionConflict {
      // One active selection only (SEL-02): show the existing one instead.
    } finally {
      _busy = false;
    }
    // The cached selection is still «none»; reload it or 14 bounces back here.
    final _ = await ref.refresh(selectionProvider(widget.requestId).future);
    if (mounted) context.go(Routes.chosen(widget.requestId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(offersProvider(widget.requestId));
    if (widget.forceError || (async.hasError && async.value == null)) {
      return OffersErrorScreen(
        onRetry: () => widget.forceError
            ? context.go(Routes.offers(widget.requestId))
            : ref.invalidate(offersProvider(widget.requestId)),
      );
    }
    final board = async.value;
    if (board == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    final chosen = ref.watch(selectionProvider(widget.requestId)).value;
    final cheapest = board.cheapest?.id;
    final confirm = _confirm == null ? null : board.byId(_confirm!);
    final all = board.sorted(_sort);
    final list = [
      for (final o in all)
        if (!_hidden.contains(o.id) && !_onlyHidden) o,
    ];
    // Preview of 47 opens with its toast, as in the design frame.
    if (!_previewToastDone && widget.hidden.isNotEmpty) {
      _previewToastDone = true;
      final h = board.byId(widget.hidden.first);
      if (h != null) _toast = OfferStrings.hiddenToast(h.pageName);
    }
    final hiddenList = [
      for (final o in all)
        if (_hidden.contains(o.id)) o,
    ];
    Widget card(Offer o) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Opacity(
        opacity: chosen != null && chosen.offer.id != o.id ? .5 : 1,
        child: GestureDetector(
          onLongPress: confirm == null && chosen == null
              ? () => _hide(o)
              : null,
          child: OfferCard(
            offer: o,
            cheapest: o.id == cheapest,
            onTap: confirm == null && chosen == null ? () => _open(o) : null,
          ),
        ),
      ),
    );

    final Widget content;
    if (confirm == null) {
      final left = board.maxOffers - board.offers.length;
      content = SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: OfferStrings.offersArrived(board.offers.length),
              titleIcon: OfferIcon.fire.of(const Color(0xFFFF7A59), 22),
              subtitle: Text(
                _hidden.isEmpty
                    ? OfferStrings.pricesFixed
                    : OfferStrings.hiddenCount(_hidden.length),
              ),
              onBack: _back,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (s, l) in const [
                    (OfferSort.cheapest, OfferStrings.sortCheapest),
                    (OfferSort.topRated, OfferStrings.sortTopRated),
                    (OfferSort.fastest, OfferStrings.sortFastest),
                  ])
                    AppChip(
                      l,
                      selected: _sort == s && !_onlyHidden,
                      onTap: () => setState(() {
                        _sort = s;
                        _onlyHidden = false;
                      }),
                    ),
                  if (_hidden.isNotEmpty)
                    AppChip(
                      OfferStrings.hiddenChip(_hidden.length),
                      selected: _onlyHidden,
                      onTap: () => setState(() => _onlyHidden = !_onlyHidden),
                    ),
                ],
              ),
            ),
            if (chosen != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: AppCard(
                  flat: true,
                  color: AppColors.blueTint,
                  insets: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      AppSvgIcon(
                        AppIcon.check,
                        size: 18,
                        color: AppColors.infoText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          OfferStrings.alreadyChose(chosen.offer.pageName),
                          style: AppText.muted.copyWith(
                            color: AppColors.infoText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: AppButton(
                  OfferStrings.backToWhatsapp,
                  variant: AppButtonVariant.navy,
                  onPressed: () => context.go(Routes.chosen(widget.requestId)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            for (final o in list) card(o),
            for (final o in hiddenList)
              _HiddenRow(
                offer: o,
                onUnhide: () => setState(() {
                  _hidden.remove(o.id);
                  if (_hidden.isEmpty) _onlyHidden = false;
                }),
              ),
            if (left > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: DashedCard(
                  child: Text(
                    _hidden.isEmpty
                        ? OfferStrings.placesLeft(
                            AppStrings.placesLeft(left),
                            board.maxOffers,
                          )
                        : OfferStrings.hiddenPlaces(
                            AppStrings.placesLeft(left),
                          ),
                    textAlign: TextAlign.center,
                    style: AppText.muted,
                    // Inline span in a 14px block: the line box is 21px, not 19.
                    strutStyle: const StrutStyle(
                      fontFamily: AppText.family,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            if (_hidden.isEmpty && list.any((o) => o.sponsored)) ...[
              const SizedBox(height: 12),
              Text(
                OfferStrings.sponsoredNote,
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
            ],
          ],
        ),
      );
    } else {
      // 13: chosen offer pinned on top of the blurred list.
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: OfferStrings.offersArrived(board.offers.length),
                titleIcon: OfferIcon.fire.of(const Color(0xFFFF7A59), 22),
                onBack: _back,
              ),
              card(confirm),
              for (final o in list)
                if (o.id != confirm.id) card(o),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: confirm == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _confirm = null);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (_toast case final t? when confirm == null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 110 + MediaQuery.viewPaddingOf(context).bottom,
                child: OfflineBanner(
                  t,
                  icon: AppIcon.refresh,
                  iconColor: AppColors.white,
                ),
              ),
            if (confirm != null) ...[
              GestureDetector(
                onTap: () => setState(() => _confirm = null),
                child: const ColoredBox(color: Color(0x8C070E1F)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ConfirmSheet(
                  offer: confirm,
                  onYes: () => _select(confirm),
                  onNo: () => setState(() => _confirm = null),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 13
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.offer,
    required this.onYes,
    required this.onNo,
  });
  final Offer offer;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    Widget point(Widget icon, String text) => Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      // Every `.li` keeps its rule: the buttons follow, so none is :last-child.
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
    return AppSheet(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                offer.image,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OfferStrings.confirmTitle(offer.pageName),
                    style: AppText.strong.copyWith(
                      fontSize: 17,
                      height: AppText.lh(17),
                    ),
                  ),
                  Text(
                    OfferStrings.confirmSub(
                      thousands(offer.price),
                      offer.delivery,
                    ),
                    style: AppText.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        point(
          const AppSvgIcon(AppIcon.user, size: 20, color: AppColors.blue),
          OfferStrings.pointPhone,
        ),
        point(
          const AppSvgIcon(
            AppIcon.whatsapp,
            size: 20,
            color: AppColors.whatsapp,
          ),
          OfferStrings.pointWhatsapp,
        ),
        point(
          const AppSvgIcon(AppIcon.clock, size: 20, color: AppColors.blue),
          OfferStrings.pointNoReply,
        ),
        point(
          const AppSvgIcon(AppIcon.shield, size: 20, color: AppColors.blue),
          OfferStrings.pointPrivacy,
        ),
        const SizedBox(height: 16),
        AppButton(OfferStrings.confirmYes, onPressed: onYes),
        const SizedBox(height: 10),
        AppButton(
          OfferStrings.confirmNo,
          variant: AppButtonVariant.ghost,
          onPressed: onNo,
        ),
      ],
    );
  }
}

/// 47 · a hidden offer: dimmed tan row with «رجّعه».
class _HiddenRow extends StatelessWidget {
  const _HiddenRow({required this.offer, required this.onUnhide});
  final Offer offer;
  final VoidCallback onUnhide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: AppCard(
      flat: true,
      color: AppColors.tabTrack,
      insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Opacity(
            opacity: .6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                offer.image,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  OfferStrings.hiddenTag(offer.pageName),
                  style: AppText.strong,
                ),
                Text(
                  OfferStrings.hiddenSub(thousands(offer.price)),
                  style: AppText.muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            child: AppButton(
              OfferStrings.unhide,
              compact: true,
              variant: AppButtonVariant.ghost,
              onPressed: onUnhide,
            ),
          ),
        ],
      ),
    ),
  );
}
