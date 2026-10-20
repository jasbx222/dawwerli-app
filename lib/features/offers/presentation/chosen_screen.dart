import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/whatsapp.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/offer_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../data/offers_providers.dart';
import '../domain/offer.dart';
import 'widgets/offer_widgets.dart';

/// 14 · Offer chosen → WhatsApp hand-off; 14b · «ما ردت» unlocked after 1h + toast.
class ChosenScreen extends ConsumerStatefulWidget {
  const ChosenScreen({
    super.key,
    required this.requestId,
    this.frozenElapsed,
    this.toast,
    this.noneLeft = false,
  });

  /// Design QA: show the «ما بقت عروض ثانية» card.
  final bool noneLeft;

  final String requestId;

  /// Design QA: pin the time since selection (no ticking).
  final Duration? frozenElapsed;

  /// Design QA: keep the 14b toast on screen.
  final String? toast;

  @override
  ConsumerState<ChosenScreen> createState() => _ChosenScreenState();
}

class _ChosenScreenState extends ConsumerState<ChosenScreen> {
  Timer? _tick;
  late String? _toast = widget.toast;
  late bool _noneLeft = widget.noneLeft;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.frozenElapsed == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _message(Selection s) =>
      OfferStrings.waMessage(s.orderNo, s.itemTitle, thousands(s.offer.price));

  Future<void> _whatsapp(Selection s) => openWhatsApp(s.pagePhone, _message(s));

  Future<void> _noReply() async {
    if (_busy) return;
    _busy = true;
    final next = await ref
        .read(offersRepositoryProvider)
        .noReply(widget.requestId);
    ref.invalidate(offersProvider(widget.requestId));
    if (!mounted) return;
    if (next == null) {
      setState(() => _noneLeft = true);
      _busy = false;
      return;
    }
    {
      setState(
        () => _toast = OfferStrings.backToOffers(
          next.pageName,
          thousands(next.price),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1800));
    }
    // Dropped offer must not show as «اخترت…» on 11.
    final _ = await ref.refresh(selectionProvider(widget.requestId).future);
    if (mounted) context.go(Routes.offers(widget.requestId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(selectionProvider(widget.requestId));
    final s = async.value;
    if (s == null) {
      if (async.hasValue && !async.isLoading) {
        // Nothing selected (yet / any more): back to the offers.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(Routes.offers(widget.requestId)),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    final elapsed =
        widget.frozenElapsed ?? DateTime.now().difference(s.selectedAt);
    final left = s.noReplyAfter - elapsed;
    final open = left <= Duration.zero;
    final mmss =
        '${left.inMinutes.toString().padLeft(2, '0')}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';

    Widget m(double top, Widget child) =>
        Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: child);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: OfferStrings.foundIt,
                  titleIcon: OfferIcon.target.of(AppColors.gold, 22),
                  subtitle: Text(OfferStrings.orderWaiting(s.orderNo)),
                  onBack: () => context.go(Routes.home),
                ),
                m(
                  14,
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                bottom: 10,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  s.offer.image,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Text(
                              OfferStrings.pageSawPhone(s.offer.pageName),
                              style: AppText.strong.copyWith(
                                fontSize: 17,
                                height: AppText.lh(17),
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: OfferStrings.lockedPrice,
                                  ),
                                  TextSpan(
                                    text:
                                        '${thousands(s.offer.price)} ${OfferStrings.iqd}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              style: AppText.muted,
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: -10,
                        left: 20,
                        child: Sticker(OfferStrings.foundSticker),
                      ),
                    ],
                  ),
                ),
                m(
                  14,
                  AppCard(
                    flat: true,
                    color: AppColors.successBg,
                    child: Text(
                      '«${_message(s)}»',
                      strutStyle: const StrutStyle(
                        fontFamily: AppText.family,
                        fontSize: 12.5,
                        height: 1.7,
                        forceStrutHeight: true,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      style: AppText.muted.copyWith(
                        color: const Color(0xFF0E4D2A),
                        height: 1.7,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ),
                ),
                m(
                  12,
                  AppCard(
                    flat: true,
                    color: AppColors.dangerBg,
                    insets: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: const NoPrepayText(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconLabelButton(
                    label: OfferStrings.openWhatsapp,
                    icon: AppIcon.whatsapp,
                    bg: AppColors.whatsapp,
                    onPressed: () => _whatsapp(s),
                  ),
                ),
                if (_noneLeft)
                  m(
                    14,
                    AppCard(
                      padding: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.warnBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: const AppSvgIcon(
                                  AppIcon.clock,
                                  color: AppColors.warn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      OfferStrings.noneLeftTitle,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        height: 1.514337,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warn,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      OfferStrings.noneLeftBody,
                                      style: AppText.muted.copyWith(
                                        height: 19 / 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            OfferStrings.repost,
                            compact: true,
                            onPressed: () => context.go(Routes.post),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            OfferStrings.raisePrice,
                            variant: AppButtonVariant.ghost,
                            compact: true,
                            onPressed: () => context.push(
                              Uri(
                                path: Routes.postDetails,
                                queryParameters: {
                                  'editPrice': widget.requestId,
                                },
                              ).toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  m(
                    14,
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const AppSvgIcon(
                                AppIcon.clock,
                                size: 22,
                                color: AppColors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      OfferStrings.noReplyQ,
                                      style: AppText.strong.copyWith(
                                        height: AppText.lh(14),
                                      ),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        children: open
                                            ? const [
                                                TextSpan(
                                                  text:
                                                      OfferStrings.noReplyOpen,
                                                ),
                                              ]
                                            : [
                                                const TextSpan(
                                                  text: OfferStrings
                                                      .noReplyLocked,
                                                ),
                                                TextSpan(
                                                  text: mmss,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontFeatures: [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                      ),
                                      style: AppText.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            OfferStrings.noReplyBtn,
                            variant: open
                                ? AppButtonVariant.navy
                                : AppButtonVariant.disabled,
                            onPressed: _noReply,
                          ),
                        ],
                      ),
                    ),
                  ),
                m(
                  14,
                  GestureDetector(
                    onTap: () => context.push(Routes.report('o1', reason: 2)),
                    child: AppCard(
                      child: Row(
                        children: [
                          OfferIcon.alert.of(AppColors.danger, 20),
                          const SizedBox(width: 12),
                          Text(OfferStrings.priceChanged, style: AppText.body),
                          const Spacer(),
                          const Text(
                            OfferStrings.report,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_noneLeft && _toast != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              // Toast never swallows taps meant for «ما ردت» under it.
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 14),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      OfferIcon.refresh.of(AppColors.white, 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: '${_toast!} ',
                            children: [
                              iconSpan(
                                OfferIcon.okHand,
                                AppColors.goldSoft,
                                16,
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: AppText.lh(13.5),
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
