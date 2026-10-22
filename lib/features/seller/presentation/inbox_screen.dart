import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/countdown.dart';
import '../../../core/widgets/pill.dart';
import '../../store/presentation/store_screens.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'widgets/seller_nav.dart';
import 'widgets/seller_widgets.dart';

const requestReportReasons = [
  'غرض ممنوع',
  'بالطلب رقم أو حساب',
  'كلام مسيء',
  'طلب وهمي أو مكرر',
];

/// 19 · «طلبات تناسبك» — matching open requests; customer phone hidden.
class SellerInboxScreen extends ConsumerWidget {
  const SellerInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final set = s.settings;
    final gov = set.governorates.firstOrNull;
    final cats = set.categories.take(2).join('، ');
    final scope = [
      if (gov != null && gov.isNotEmpty) gov,
      if (cats.isNotEmpty) cats,
    ].join(' · ');
    final open = s.inbox
        .where((r) => !r.offeredByMe && !r.locked(s.config.maxOffers))
        .firstOrNull;
    return AppPage(
      title: 'طلبات تناسبك',
      showBack: false,
      trailing: scope.isEmpty
          ? null
          : Pill(
              scope,
              bg: AppColors.white.withValues(alpha: .18),
              fg: AppColors.white,
            ),
      nav: const SellerNav(SellerTab.inbox),
      children: [
        if (s.status != VerifyStatus.verified)
          Gap(
            StateCardLink(
              title: 'صفحتك بعدها مو موثّقة',
              body: 'الطلبات توصل بس للصفحات الموثقة. كمّل التوثيق.',
              action: 'كمّل التوثيق',
              onTap: () => context.push(sellerEntryRoute(s.status)),
            ),
          ),
        if (s.suspended)
          Gap(
            StateCardLink(
              title: 'صفحتك موقوفة',
              body: 'ما توصلك طلبات لحد ما يخلص الإيقاف.',
              action: 'شوف حالة صفحتك',
              onTap: () => context.push(Routes.sellerStanding),
            ),
          ),
        if (!set.receiving)
          Gap(
            StateCardLink(
              title: 'استلام الطلبات متوقف',
              body: 'طفّيته من الإعدادات، فما توصلك طلبات جديدة.',
              action: 'شغّله',
              onTap: () => context.push(Routes.sellerSettings),
            ),
          ),
        if (s.earlyAccess) const Gap(_EarlyBanner()),
        Gap(
          Row(
            children: [
              Expanded(
                child: AppButton(
                  'قدّم عرض',
                  compact: true,
                  onPressed: open == null
                      ? () => showAppToast(
                          context,
                          'ماكو طلب مفتوح هسه. لمن يجي طلب، قدّم عرضك من هنا',
                        )
                      : () => context.push(Routes.sellerSubmit(open.id)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  'أضف إعلان',
                  compact: true,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.push(Routes.sellerAds),
                ),
              ),
            ],
          ),
        ),
        if (s.inbox.isEmpty)
          const Gap(
            AppCard(
              flat: true,
              child: Text(
                'ماكو طلبات تناسب صفحتك هسه. الطلب يطلع هنا، وتقدّم عرضك عليه. الإعلان من «أضف إعلان».',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SectionLabel('طلبات الزباين'),
        ref.watch(pageStoreOrdersProvider).when(
          loading: () => const Gap(Text('نجيب الطلبات...')),
          error: (_, _) => const Gap(Text('ما قدرنا نجيب طلبات المتجر')),
          data: (orders) => orders.isEmpty
              ? const Gap(
                  AppCard(
                    flat: true,
                    child: Text(
                      'ماكو طلبات متجر هسه',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final o in orders)
                      Gap(
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${o.no} · ${o.pageName}', style: AppText.strong),
                              const SizedBox(height: 4),
                              Text(
                                '${o.items.join('، ')}\n${o.subtotal} د.ع',
                                style: AppText.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        for (final r in s.inbox) Gap(_RequestCard(r)),
        Gap(
          Text(
            'رقم الزبون مخفي · تشوف عدد العروض بس، مو أسعارها',
            textAlign: TextAlign.center,
            style: AppText.muted,
          ),
          top: 10,
        ),
      ],
    );
  }
}

class StateCardLink extends StatelessWidget {
  const StateCardLink({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: AppColors.warnBg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.strong.copyWith(color: AppColors.warn)),
        Text(body, style: AppText.muted.copyWith(color: AppColors.warnText)),
        const SizedBox(height: 10),
        AppButton(action, compact: true, onPressed: onTap),
      ],
    ),
  );
}

class _EarlyBanner extends StatelessWidget {
  const _EarlyBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.card),
      gradient: const LinearGradient(
        begin: Alignment(-0.866, -0.5),
        end: Alignment(0.866, 0.5),
        colors: [AppColors.navy, AppColors.blue],
      ),
    ),
    child: Row(
      children: [
        const AppSvgIcon(AppIcon.zap, color: AppColors.goldSoft, size: 24),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'إشعار قبل غيرك',
                  style: AppText.strong.copyWith(color: AppColors.white),
                ),
                const SizedBox(width: 4),
                const AppSvgIcon(
                  AppIcon.boltSmall,
                  color: AppColors.goldSoft,
                  size: 14,
                ),
              ],
            ),
            const Text(
              'مشترك: الطلبات توصلك قبل دقيقتين',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.headerSub,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard(this.r);
  final SellerRequest r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(sellerProvider).config;
    final locked = r.locked(c.maxOffers);
    final mins = DateTime.now().difference(r.postedAt).inMinutes;
    return ThumbCard(
      image: r.image,
      title: r.title,
      sub:
          '${r.governorate} · ${r.condition} · حد السعر ${iqd(r.maxPrice)} · قبل ${mins < 1 ? 1 : mins} د',
      footer: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (r.earlyUntil != null)
                    Countdown(
                      until: r.earlyUntil!,
                      builder: (_, left) => left == Duration.zero
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: EdgeInsets.zero,
                              child: PillTone.gold.pill(
                                'مبكر · ${mmss(left)}',
                                icon: AppIcon.zap,
                              ),
                            ),
                    ),
                  locked
                      ? PillTone.blue.pill(
                          '${c.maxOffers}/${c.maxOffers} · انقفل',
                        )
                      : PillTone.blue.pill('${r.offers}/${c.maxOffers} عروض'),
                  GestureDetector(
                    onTap: () => ReasonSheet.show(
                      context,
                      title: 'بلّغ عن الطلب',
                      sub: 'الزبون ما يعرف إنك بلّغت',
                      reasons: requestReportReasons,
                      onSend: (_) => showAppToast(context, 'وصل بلاغك، نراجعه'),
                    ),
                    child: Row(
                      children: [
                        AppSvgIcon(
                          AppIcon.flag,
                          color: AppColors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text('بلّغ', style: AppText.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SmallButton(
              r.offeredByMe ? 'دزيت عرضك' : (locked ? 'انقفل' : 'قدّم عرض'),
              icon: locked || r.offeredByMe ? AppIcon.lock : AppIcon.camera,
              variant: locked || r.offeredByMe
                  ? AppButtonVariant.disabled
                  : AppButtonVariant.primary,
              onPressed: locked
                  ? null
                  : () => context.push(Routes.sellerSubmit(r.id)),
            ),
          ],
        ),
      ),
    );
  }
}
