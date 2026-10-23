import 'package:flutter/material.dart';

import '../../../core/widgets/app_image.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/offer_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../more/more_data.dart';
import '../data/offers_providers.dart';
import 'widgets/offer_widgets.dart';

/// 12 · One offer: live-camera photo, locked price, delivery, safety tips, «أريده».
class OfferDetailsScreen extends ConsumerWidget {
  const OfferDetailsScreen({
    super.key,
    required this.requestId,
    required this.offerId,
  });

  final String requestId;
  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(offersProvider(requestId));
    final board = async.value;
    final o = board?.byId(offerId);
    // A just-sent offer may not be in the cached board yet: wait for the
    // re-read instead of bouncing straight back to the list.
    if (board == null || (o == null && async.isLoading)) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    void back([bool? want]) => context.canPop()
        ? context.pop(want)
        : context.go(
            Routes.offers(requestId) +
                (want == true ? '?confirm=$offerId' : ''),
          );
    if (o == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => back());
      return Scaffold();
    }
    Widget m(double top, Widget child) =>
        Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: child);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 380,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(o.image, fit: BoxFit.cover),
                      Positioned(
                        top: 50,
                        right: 16,
                        child: GestureDetector(
                          onTap: back,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon(
                              AppIcon.back,
                              size: 20,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: .7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: '${o.photoStamp} ',
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: AppSvgIcon(
                                    AppIcon.camera,
                                    size: 12,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 11,
                              height: AppText.lh(11),
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 14,
                        child: Pill(
                          OfferStrings.liveCamera,
                          bg: AppColors.white,
                          fg: AppColors.navy,
                          icon: AppIcon.camera,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      m(
                        0,
                        AppCard(
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: OfferStrings.pageVerified(
                                        o.pageName,
                                      ),
                                      children: [checkSpan(18, AppColors.ink)],
                                    ),
                                    style: AppText.strong.copyWith(
                                      fontSize: 18,
                                      height: AppText.lh(18),
                                    ),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        starSpan,
                                        TextSpan(
                                          text: OfferStrings.detailStats(
                                            rating1(o.rating),
                                            o.deals,
                                            ref.watch(pageProfileProvider(o.pageId)).value?.replyMinutes ?? o.replyMinutes,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: AppText.muted,
                                  ),
                                ],
                              ),
                              Spacer(),
                              if (o.trusted)
                                Pill(
                                  OfferStrings.trusted,
                                  bg: AppColors.blueTint,
                                  fg: AppColors.blue,
                                ),
                            ],
                          ),
                        ),
                      ),
                      m(
                        14,
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.baseline,
                                          baseline: TextBaseline.alphabetic,
                                          child: AppSvgIcon(
                                            AppIcon.lock,
                                            size: 15,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                        TextSpan(
                                          text: OfferStrings.finalLocked,
                                        ),
                                      ],
                                    ),
                                    style: AppText.muted,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${thousands(o.price)} ${OfferStrings.iqd}',
                                    style: AppText.number.copyWith(
                                      fontSize: 22,
                                      height: AppText.lh(22),
                                      color: AppColors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.divider),
                                  ),
                                ),
                                child: InfoRow(
                                  label: OfferStrings.delivery,
                                  value: OfferStrings.deliveryIncluded(
                                    o.delivery,
                                  ),
                                ),
                              ),
                              InfoRow(
                                label: OfferStrings.condition,
                                value: o.condition,
                              ),
                              InfoRow(
                                label: OfferStrings.pageNote,
                                value: o.note,
                                valueSize: 13,
                                divider: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      m(
                        14,
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
                      m(
                        14,
                        AppCard(
                          flat: true,
                          color: AppColors.warnBg,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                iconSpan(OfferIcon.bulb, AppColors.gold, 15),
                                const TextSpan(
                                  text: ' ${OfferStrings.inspectTip}',
                                ),
                              ],
                            ),
                            style: AppText.muted.copyWith(
                              color: AppColors.warnText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: GestureDetector(
              onTap: () => back(true),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99E8B33A),
                      offset: Offset(0, 12),
                      blurRadius: 24,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      OfferStrings.want,
                      style: AppText.button.copyWith(
                        color: AppColors.navy,
                        height: AppText.lh(16),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OfferIcon.target.of(AppColors.navy, 18),
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
