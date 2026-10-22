import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/countdown.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/sticker.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/loading_block.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'widgets/page_side_widgets.dart';
import 'widgets/seller_nav.dart';
import 'widgets/seller_widgets.dart';

const customerReportReasons = [
  'طلب مني رقم أو حساب',
  'طلب يدفع برا التطبيق',
  'كلام مسيء',
  'اختار وما رد',
  'طلب غرض ممنوع',
];

/// 21 · «عروضي» — every offer this page sent with its live status.
/// Polls while on screen; a chip row filters by status.
class SellerOffersScreen extends ConsumerStatefulWidget {
  const SellerOffersScreen({super.key});

  @override
  ConsumerState<SellerOffersScreen> createState() => _OffersState();
}

class _OffersState extends ConsumerState<SellerOffersScreen>
    with WidgetsBindingObserver, PagePolling {
  OfferState? _state;
  bool _loading = true;
  Object? _error;
  DateTime? _updated;

  static const _order = [
    OfferState.waiting,
    OfferState.chosen,
    OfferState.notChosen,
    OfferState.withdrawn,
    OfferState.closed,
  ];

  static String _label(OfferState s) => switch (s) {
    OfferState.waiting => 'بالانتظار',
    OfferState.chosen => 'انختارت',
    OfferState.notChosen => 'ما انختارت',
    OfferState.withdrawn => 'سحبتها',
    OfferState.closed => 'انتهت',
  };

  @override
  void initState() {
    super.initState();
    startPolling();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await ref.read(sellerProvider.notifier).loadOffers();
      if (!mounted) return;
      setState(() {
        _error = null;
        _updated = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Future<void> poll() => _refresh();

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(sellerProvider).offers;
    int count(OfferState s) => offers.where((o) => o.state == s).length;
    final shown =
        [
          for (final o in offers)
            if (_state == null || o.state == _state) o,
        ]..sort(
          (a, b) =>
              (b.sentAt ?? DateTime(0)).compareTo(a.sentAt ?? DateTime(0)),
        );
    return AppPage(
      title: 'عروضي',
      showBack: false,
      trailing: count(OfferState.waiting) > 0
          ? Pill(
              '${count(OfferState.waiting)} بالانتظار',
              bg: AppColors.white.withValues(alpha: .18),
              fg: AppColors.white,
            )
          : null,
      nav: const SellerNav(SellerTab.offers),
      onRefresh: _refresh,
      children: [
        ChipRow(
          children: [
            choiceChip(
              'الكل (${offers.length})',
              _state == null,
              () => setState(() => _state = null),
            ),
            for (final s in _order)
              choiceChip(
                '${_label(s)} (${count(s)})',
                _state == s,
                () => setState(() => _state = s),
              ),
          ],
        ),
        Gap(
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _error == null ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _error != null
                      ? 'ما كدرنا نحدّث، نحاول مرة ثانية'
                      : _updated == null
                      ? 'دنحدّث الحالة...'
                      : 'الحالة تتحدث تلقائياً · آخر تحديث ${agoLabel(_updated!)}',
                  style: AppText.muted,
                ),
              ),
            ],
          ),
          top: 10,
        ),
        if (_loading && offers.isEmpty)
          const ListSkeleton()
        else if (_error != null && offers.isEmpty)
          Gap(RetryCard(error: _error!, onRetry: _refresh))
        else if (shown.isEmpty)
          Gap(
            EmptyStateCard(
              icon: AppIcon.message,
              title: _state == null
                  ? 'بعدك ما دزيت عروض'
                  : 'ماكو عروض ${_label(_state!)}',
              body: 'قدّم عرضك على طلبات الزباين من الهوم',
              action: AppButton(
                'روح للهوم',
                compact: true,
                variant: AppButtonVariant.ghost,
                onPressed: () => context.go(Routes.sellerHome),
              ),
            ),
          )
        else
          ResponsiveCards(children: [for (final o in shown) _OfferCard(o)]),
      ],
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard(this.o);
  final SellerOffer o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(sellerProvider.notifier);
    final c = ref.watch(sellerProvider).config;
    if (o.state == OfferState.withdrawn) {
      return TintedNote(
        'رجعلك ${iqd(c.selectionFee)} المحجوزة',
        title: 'سحبت عرض «${o.title}»',
        bg: TintedNote.tealBg,
        fg: TintedNote.tealFg,
      );
    }
    final since = o.chosenAt == null
        ? Duration.zero
        : DateTime.now().difference(o.chosenAt!);
    final ghostWindow = since >= c.ghostAfter;
    final title = o.title;
    final sub = [
      'عرضك ${iqd(o.price)}',
      if (o.category.isNotEmpty) o.category,
      if (o.sentAt != null) 'دزيته ${agoLabel(o.sentAt!.toLocal())}',
      if (o.requestMaxPrice != null) 'حد الزبون ${iqd(o.requestMaxPrice!)}',
    ].join(' · ');
    return switch (o.state) {
      OfferState.chosen when ghostWindow => ThumbCard(
        image: o.image,
        title: title,
        sub: sub.isEmpty ? 'عرضك مقفول' : sub,
        trailing: PillTone.gold.pill('من ${since.inHours} ساعة'),
        onTap: () => context.push(Routes.sellerChosen(o.id)),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'الزبون ما رد من ${c.ghostAfter.inHours} ساعة؟ نسأله أول «وصلك الغرض؟» قبل أي استرجاع',
              style: AppText.muted,
            ),
            const SizedBox(height: 10),
            o.ghostReported
                ? PillTone.gold.pill(
                    'بلّغت · ننتظر جواب الزبون',
                    icon: AppIcon.hourglass,
                  )
                : AppButton(
                    'زبون ما رد',
                    compact: true,
                    icon: AppIcon.flag,
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
                      ctl.reportGhost(o.id);
                      showAppToast(
                        context,
                        'نسأل الزبون «وصلك الغرض؟» ونرجعلك',
                      );
                    },
                  ),
          ],
        ),
      ),
      OfferState.chosen => ThumbCard(
        image: o.image,
        title: title,
        sub: sub.isEmpty ? 'عرضك مقفول' : sub,
        trailing: o.contacted
            ? PillTone.teal.pill('تواصلت', check: true)
            : PillTone.gold.pill('رد خلال ساعة'),
        onTap: () => context.push(Routes.sellerChosen(o.id)),
        footer: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _ContactButtons(o),
        ),
      ),
      OfferState.waiting => ThumbCard(
        image: o.image,
        title: title,
        sub: sub.isEmpty ? 'عرضك مقفول' : sub,
        trailing: PillTone.blue.pill('بالانتظار'),
        onTap: () => context.push(Routes.sellerOfferView(o.id)),
        footer: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Text('الزبون بعده ما اختار', style: AppText.muted),
              const Spacer(),
              SmallButton(
                'اسحب العرض',
                variant: AppButtonVariant.ghost,
                onPressed: () => ctl.withdraw(o.id),
              ),
            ],
          ),
        ),
      ),
      OfferState.notChosen => ThumbCard(
        image: o.image,
        title: title,
        sub: sub.isEmpty ? 'عرضك مقفول' : sub,
        trailing: PillTone.stone.pill('الزبون اختار غيرك'),
        onTap: () => context.push(Routes.sellerOfferView(o.id)),
        footer: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text('ما انخصم شي، الحجز رجع لرصيدك', style: AppText.muted),
        ),
      ),
      _ => ThumbCard(
        image: o.image,
        title: title,
        sub: sub.isEmpty ? 'عرضك مقفول' : sub,
        trailing: PillTone.stone.pill('انتهى'),
        onTap: () => context.push(Routes.sellerOfferView(o.id)),
        footer: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              AppSvgIcon(AppIcon.lock, color: AppColors.grey, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'الطلب تسكّر، فانشال رقم الزبون من عندك نهائياً',
                  style: AppText.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

/// «افتح الطلب» + «تواصلت ويا الزبون» (21 row, 21b).
class _ContactButtons extends ConsumerWidget {
  const _ContactButtons(this.o, {this.stacked = false});
  final SellerOffer o;
  final bool stacked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wa = AppButton(
      'افتح الطلب',
      compact: true,
      icon: AppIcon.clipboardList,
      onPressed: o.storeOrderId == null
          ? null
          : () => context.push(Routes.sellerOrder(o.storeOrderId!)),
    );
    final contacted = AppButton(
      'تواصلت ويا الزبون',
      compact: !stacked,
      icon: AppIcon.check,
      variant: o.contacted ? AppButtonVariant.disabled : AppButtonVariant.navy,
      onPressed: o.contacted
          ? null
          : () {
              ref.read(sellerProvider.notifier).markContacted(o.id);
              showAppToast(context, 'سجّلنا إنك تواصلت ويا الزبون');
            },
    );
    if (stacked) return contacted;
    return Row(
      children: [
        Expanded(flex: 10, child: wa),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 13, child: contacted),
      ],
    );
  }
}

/// 21b · a customer chose this offer (21d sheet: report the customer).
class SellerChosenScreen extends ConsumerWidget {
  const SellerChosenScreen({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final o = s.offers.firstWhere((x) => x.id == offerId);
    final c = s.config;
    return AppPage(
      title: 'اختارك زبون',
      titleIcon: const AppSvgIcon(
        AppIcon.party,
        color: AppColors.goldSoft,
        size: 20,
      ),
      subtitle: 'طلب #${o.orderNo}',
      onBack: () => popOr(context, Routes.sellerOffers),
      children: [
        Gap(
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppCard(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    PhotoThumb(o.image, size: 90, radius: 24),
                    const SizedBox(height: 10),
                    Text(
                      'الزبون اختار عرضك',
                      style: AppText.strong.copyWith(fontSize: 17),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'طلب '),
                          TextSpan(
                            text: '#${o.orderNo}',
                            style: AppText.number.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const TextSpan(text: ' · السعر المقفول '),
                          TextSpan(
                            text: iqd(o.price),
                            style: AppText.number.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      style: AppText.muted,
                    ),
                  ],
                ),
              ),
              const Positioned(top: -10, left: 20, child: Sticker('لكيته!')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            'افتح الطلب',
            icon: AppIcon.clipboardList,
            onPressed: o.storeOrderId == null
                ? null
                : () => context.push(Routes.sellerOrder(o.storeOrderId!)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppSvgIcon(AppIcon.clock, color: AppColors.blue, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رد خلال ساعة', style: AppText.strong),
                          Countdown(
                            until: (o.chosenAt ?? DateTime.now()).add(
                              c.replyWindow,
                            ),
                            builder: (_, left) => Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'باقي '),
                                  TextSpan(
                                    text: mmss(left),
                                    style: AppText.number,
                                  ),
                                  const TextSpan(
                                    text: ' · إذا ما رديت تاخذ علامة «ما ردت»',
                                  ),
                                ],
                              ),
                              style: AppText.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ContactButtons(o, stacked: true),
              ],
            ),
          ),
        ),
        Gap(
          TintedNote(
            'رقم الزبون وعنوانه يبينون بس داخل الطلب، وينشالون من عندك نهائياً أول ما يتسكر.',
            bg: TintedNote.blueBg,
            fg: TintedNote.blueFg,
            icon: AppIcon.lock,
          ),
        ),
        if (o.selectionNo != null)
          Gap(
            TintedNote(
              o.selectionNo! > c.freeSelections
                  ? 'الاختيار ${o.selectionNo} · انخصم ${iqd(c.selectionFee)} من رصيدك'
                  : 'الاختيار ${o.selectionNo} · مجاني (${o.selectionNo} من ${c.freeSelections})',
              bg: AppColors.warnBg,
              fg: AppColors.warnText,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            'بلّغ عن الزبون',
            icon: AppIcon.flag,
            variant: AppButtonVariant.ghost,
            onPressed: () => ReasonSheet.show(
              context,
              title: 'بلّغ عن الزبون',
              sub: 'طلب #${o.orderNo} · الزبون ما يعرف إنك بلّغت',
              reasons: customerReportReasons,
              warning: 'إذا ترفع صورة محادثة، غطّي الأرقام بيها',
              onSend: (_) =>
                  showAppToast(context, 'وصل بلاغك، نراجعه خلال 48 ساعة'),
            ),
          ),
        ),
      ],
    );
  }
}

/// 21c · a rating arrived.
class SellerRatingScreen extends ConsumerWidget {
  const SellerRatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final r = s.lastRating;
    if (r == null) {
      return const AppPage(title: 'وصلك تقييم', children: [LoadingBlock()]);
    }
    return AppPage(
      title: 'وصلك تقييم',
      titleIcon: const AppSvgIcon(
        AppIcon.star,
        color: AppColors.goldSoft,
        size: 20,
      ),
      subtitle: 'طلب #${r.orderNo} · زبون من ${r.governorate}',
      onBack: () => popOr(context, Routes.sellerAccount),
      children: [
        Gap(
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AppSvgIcon(
                          AppIcon.star,
                          size: 30,
                          color: i < r.stars
                              ? AppColors.gold
                              : AppColors.checkOff,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'خوش صفحة',
                      style: AppText.strong.copyWith(fontSize: 17),
                    ),
                    const SizedBox(width: 4),
                    const AppSvgIcon(
                      AppIcon.smile,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in r.tags) AppChip(t, selected: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text('«${r.comment}»', style: AppText.muted),
              ],
            ),
          ),
        ),
        Gap(
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatTile('${s.rating}', 'تقييمك', color: AppColors.blue),
                StatTile('${s.deals}', 'صفقة بالتطبيق', color: AppColors.blue),
                Column(
                  children: [
                    s.trusted
                        ? PillTone.blue.pill('موثوقة', check: true)
                        : PillTone.stone.pill('بعدها'),
                    const SizedBox(height: 4),
                    Text('شارتك', style: AppText.muted),
                  ],
                ),
              ],
            ),
          ),
        ),
        Gap(
          TintedNote(
            'التقييم والشارة يكبرون بس من الصفقات المؤكدة داخل التطبيق.',
            bg: TintedNote.blueBg,
            fg: TintedNote.blueFg,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            'التقييم مو حقيقي؟ بلّغ',
            icon: AppIcon.flag,
            variant: AppButtonVariant.ghost,
            onPressed: () => showAppToast(context, 'وصل بلاغك، نراجع التقييم'),
          ),
        ),
      ],
    );
  }
}

class SellerOfferDetailsScreen extends ConsumerWidget {
  const SellerOfferDetailsScreen({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref
        .watch(sellerProvider)
        .offers
        .where((o) => o.id == offerId)
        .firstOrNull;
    if (offer == null) {
      return const AppPage(title: 'تفاصيل العرض', children: [LoadingBlock()]);
    }
    final state = switch (offer.state) {
      OfferState.chosen => 'الزبون اختارك',
      OfferState.waiting => 'بانتظار الزبون',
      OfferState.notChosen => 'الزبون اختار غيرك',
      OfferState.withdrawn => 'سحبت العرض',
      OfferState.closed => 'انتهى',
    };
    return AppPage(
      title: 'تفاصيل العرض',
      children: [
        Gap(
          AppCard(
            child: Row(
              children: [
                PhotoThumb(offer.image, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.title, style: AppText.strong),
                      const SizedBox(height: 4),
                      Text(state, style: AppText.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap(
          AppCard(
            child: Column(
              children: [
                _Detail('السعر', iqd(offer.price)),
                _Detail('المحافظة', offer.governorate),
                if ((offer.orderNo ?? '').isNotEmpty)
                  _Detail('رقم الطلب', offer.orderNo!),
              ],
            ),
          ),
        ),
        if (offer.state == OfferState.chosen)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              'تواصل مع الزبون',
              onPressed: () => context.push(Routes.sellerChosen(offer.id)),
            ),
          ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: AppText.muted)),
          Expanded(child: Text(value, style: AppText.strong)),
        ],
      ),
    );
  }
}
