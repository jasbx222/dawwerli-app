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
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_toggle.dart';
import '../../../core/widgets/ishtar_pattern.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/state_card.dart';
import '../../../core/api/picker.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'topup_sheet.dart';
import 'widgets/seller_widgets.dart';

extension AdSlotText on AdSlot {
  String get title => switch (this) {
    AdSlot.homeBanner => 'بانر الرئيسية',
    AdSlot.featuredPage => 'صفحة مميزة بالصنف',
    AdSlot.sponsoredOffer => 'عرض مُموّل',
  };
  AppIcon get icon => switch (this) {
    AdSlot.homeBanner => AppIcon.image,
    AdSlot.featuredPage => AppIcon.star,
    AdSlot.sponsoredOffer => AppIcon.flame,
  };
  String get unit => switch (this) {
    AdSlot.homeBanner => 'باليوم',
    AdSlot.featuredPage => 'بالأسبوع',
    AdSlot.sponsoredOffer => 'بالطلب',
  };
  int price(SellerConfig c) => switch (this) {
    AdSlot.homeBanner => c.bannerDaily,
    AdSlot.featuredPage => c.featuredWeekly,
    AdSlot.sponsoredOffer => c.sponsoredOffer,
  };
}

extension AdStatusPill on AdStatus {
  Pill get pill => switch (this) {
    AdStatus.pending => PillTone.gold.pill(
      'قيد المراجعة',
      icon: AppIcon.hourglass,
    ),
    AdStatus.rejected => PillTone.red.pill('انرفض'),
    AdStatus.pausedBalance => PillTone.red.pill('توقف'),
    AdStatus.pausedSuspended => PillTone.red.pill('موقف'),
    AdStatus.active => PillTone.teal.pill('شغال'),
    AdStatus.ended => PillTone.teal.pill('انتهى'),
  };
}

/// 23 · «روّج لصفحتك» (23c when the page isn't eligible).
class SellerAdsScreen extends ConsumerWidget {
  const SellerAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    if (!s.canAdvertise) return const AdsEligibilityScreen();
    final c = s.config;
    final pending = s.ads.where((a) => a.status == AdStatus.pending).take(1);
    final ended = s.ads.where((a) => a.status == AdStatus.ended).take(1);
    return AppPage(
      title: 'روّج لصفحتك',
      subtitle: 'كل شي مدفوع ينكتب عليه «مُموّل»',
      onBack: () => popOr(context, Routes.sellerAccount),
      children: [
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSize.iconTile,
                      height: AppSize.iconTile,
                      decoration: BoxDecoration(
                        color: AppColors.navyFill,
                        borderRadius: BorderRadius.circular(AppRadius.iconBox),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon(
                        AppIcon.zap,
                        color: AppColors.goldSoft,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إشعار قبل غيرك', style: AppText.strong),
                          Text(
                            'دقيقتين قبل الكل · أقصى ${c.maxEarlySlots} من ${c.maxOffers} عروض',
                            style: AppText.muted,
                          ),
                        ],
                      ),
                    ),
                    AppToggle(
                      on: s.earlyAccess,
                      onTap: () {
                        if (!s.earlyAccess &&
                            s.balance < c.earlyAccessMonthly) {
                          TopupSheet.show(context);
                          return;
                        }
                        ref.read(sellerProvider.notifier).toggleEarly();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.earlyAccess
                      ? 'مشترك · ${thousands(c.earlyAccessMonthly)} د.ع/شهر · يتجدد 1 تشرين الثاني'
                      : 'مو مشترك · ${thousands(c.earlyAccessMonthly)} د.ع/شهر',
                  style: AppText.muted,
                ),
              ],
            ),
          ),
        ),
        Gap(
          AppCard(
            insets: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('احجز إعلان', style: AppText.strong),
                for (final slot in AdSlot.values)
                  SettingsRow(
                    slot.icon,
                    slot.title,
                    sub: switch (slot) {
                      AdSlot.homeBanner =>
                        '${s.settings.governorates.firstOrNull ?? 'محافظتك'} · ${slot.unit}',
                      AdSlot.featuredPage =>
                        'أفضل صفحات ${s.settings.categories.firstOrNull ?? 'صنوفك'} ب${s.settings.governorates.firstOrNull ?? 'محافظتك'} · ${slot.unit}',
                      AdSlot.sponsoredOffer =>
                        'عرضك ينثبت أول · ضمن الـ ${c.maxOffers} · سعره ≤ حد الزبون',
                    },
                    trailing: Text(
                      thousands(slot.price(c)),
                      style: AppText.number,
                    ),
                    onTap: () => context.push(Routes.sellerAdBook(slot.name)),
                  ),
              ],
            ),
          ),
        ),
        for (final a in pending) Gap(AdCard(a)),
        for (final a in ended) Gap(_StatsCard(a)),
        Gap(
          SettingsGroup([
            SettingsRow(
              AppIcon.chartLine,
              'إعلاناتي',
              value: '${s.ads.length}',
              onTap: () => context.push(Routes.sellerMyAds),
            ),
            SettingsRow(
              AppIcon.shieldCheck,
              'منو يكدر يعلن؟',
              onTap: () => context.push(Routes.sellerAdsEligibility),
            ),
          ], margin: false),
        ),
      ],
    );
  }
}

class AdCard extends StatelessWidget {
  const AdCard(this.a, {super.key});
  final AdCampaign a;

  @override
  Widget build(BuildContext context) => ThumbCard(
    image: a.image,
    title: a.title,
    sub: a.place,
    trailing: a.status.pill,
    footer: a.note == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(a.note!, style: AppText.muted),
          ),
  );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard(this.a);
  final AdCampaign a;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Row(
          children: [
            Text(a.title, style: AppText.strong),
            const Spacer(),
            a.status.pill,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StatTile(thousands(a.impressions), 'ظهور'),
            StatTile(thousands(a.clicks), 'ضغطة'),
            StatTile('${a.selections}', 'اختيار', color: PillTone.teal.fg),
          ],
        ),
      ],
    ),
  );
}

/// 23b · «إعلاناتي» with every status.
class SellerMyAdsScreen extends ConsumerWidget {
  const SellerMyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref
        .watch(sellerProvider)
        .ads
        .where((a) => a.status != AdStatus.ended);
    return AppPage(
      title: 'إعلاناتي',
      subtitle: 'حالات الإعلان',
      bottom: AppButton(
        '+ إعلان جديد',
        onPressed: () =>
            context.push(Routes.sellerAdBook(AdSlot.homeBanner.name)),
      ),
      children: [for (final a in ads) Gap(AdCard(a))],
    );
  }
}

/// 23c · ad eligibility: verified, rating ≥ min, no open report, no upheld complaint in 30 days.
class AdsEligibilityScreen extends ConsumerWidget {
  const AdsEligibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final ok = s.canAdvertise;
    final checks = [
      (
        s.rating >= s.config.minAdRating,
        'تقييمك ${s.rating}',
        'حسّن تقييمك بصفقات ناجحة بالتطبيق.',
        'شوف تقييماتي',
        Routes.sellerRating,
      ),
      (
        !s.openReport,
        s.openReport ? 'عندك بلاغ مفتوح' : 'ماكو بلاغ مفتوح',
        'ينحسم خلال ${s.config.appealHours} ساعة.',
        'شوف البلاغ',
        Routes.sellerStanding,
      ),
      (
        !s.suspended,
        s.suspended ? 'شكوى ثابتة آخر 30 يوم' : 'ماكو شكوى ثابتة آخر 30 يوم',
        'الإعلان ينفتح بعد 30 يوم من آخر شكوى مؤكدة.',
        'شوف التفاصيل',
        Routes.sellerStanding,
      ),
    ];
    return AppPage(
      title: 'روّج لصفحتك',
      onBack: () => popOr(context, Routes.sellerAccount),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 50, 28, 0),
          child: Column(
            children: [
              IshtarBackground(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blue, AppColors.navy],
                ),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: AppSvgIcon(
                      ok ? AppIcon.verified : AppIcon.star,
                      color: AppColors.goldSoft,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(ok ? 'تكدر تعلن' : 'ما تكدر تعلن هسه', style: AppText.big),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'الإعلانات بس للصفحات الموثقة اللي تقييمها ${s.config.minAdRating.toStringAsFixed(0)} وفوق وما عليها بلاغ مفتوح.',
                textAlign: TextAlign.center,
                style: AppText.muted.copyWith(fontSize: 14.5, height: 1.7),
              ),
            ],
          ),
        ),
        for (final (pass, title, body, action, route) in checks)
          Gap(
            StateCard(
              icon: pass ? AppIcon.check : AppIcon.alert,
              tint: pass ? PillTone.teal.bg : AppColors.dangerBg,
              tone: pass ? PillTone.teal.fg : AppColors.danger,
              title: title,
              body: TextSpan(text: pass ? 'تمام' : body),
              action: pass ? null : action,
              actionVariant: AppButtonVariant.ghost,
              onAction: () => context.push(route),
            ),
            top: 10,
          ),
      ],
    );
  }
}

/// Book a slot: targeting, duration, text + image, reserved price (moderated before showing).
class AdBookScreen extends ConsumerStatefulWidget {
  const AdBookScreen({super.key, required this.slot});
  final AdSlot slot;

  @override
  ConsumerState<AdBookScreen> createState() => _AdBookState();
}

class _AdBookState extends ConsumerState<AdBookScreen> {
  final _text = TextEditingController();
  late String _gov =
      ref.read(sellerProvider).settings.governorates.firstOrNull ?? '';
  late String _cat =
      ref.read(sellerProvider).settings.categories.firstOrNull ?? '';
  int _units = 1;
  String? _image;
  bool _busy = false;
  static const _daysPerWeek = 7;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<int> get _unitOptions =>
      widget.slot == AdSlot.featuredPage ? const [1, 2, 4] : const [1, 3, 7];

  String _unitLabel(int n) => switch (widget.slot) {
    AdSlot.featuredPage => n == 1 ? 'أسبوع' : '$n أسابيع',
    AdSlot.sponsoredOffer => n == 1 ? 'طلب واحد' : '$n طلبات',
    AdSlot.homeBanner => n == 1 ? 'يوم' : '$n أيام',
  };

  Future<void> _book(int total) async {
    if (_busy) return;
    final s = ref.read(sellerProvider);
    final text = _text.text.trim();
    final err = widget.slot == AdSlot.homeBanner && text.isEmpty
        ? 'اكتب نص البانر'
        : widget.slot == AdSlot.homeBanner && _image == null
        ? 'ارفع صورة البانر'
        : hasContact(text)
        ? 'شيل الرقم أو الرابط أو @الحساب من النص'
        : null;
    setState(() => _error = err);
    if (err != null) return;
    if (s.balance < total) {
      TopupSheet.show(context);
      return;
    }
    final title = switch (widget.slot) {
      AdSlot.homeBanner => 'بانر «$text»',
      AdSlot.featuredPage => 'صفحة مميزة · $_cat',
      AdSlot.sponsoredOffer => 'عرض مُموّل',
    };
    setState(() => _busy = true);
    try {
      await ref
          .read(sellerProvider.notifier)
          .bookAd(
            slot: widget.slot,
            title: title,
            headline: text,
            category: _cat,
            governorate: _gov,
            days: widget.slot == AdSlot.featuredPage ? _units * _daysPerWeek : _units,
            image: _image,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    showAppToast(context, 'انحجز إعلانك، ينراجع قبل النشر');
    context.pushReplacement(Routes.sellerMyAds);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sellerProvider);
    final total = widget.slot.price(s.config) * _units;
    Widget chips(List<String> opts, String sel, ValueChanged<String> on) =>
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final o in opts)
              AppChip(o, selected: o == sel, onTap: () => on(o)),
          ],
        );
    return AppPage(
      title: widget.slot.title,
      subtitle:
          '${thousands(widget.slot.price(s.config))} د.ع ${widget.slot.unit} · ينكتب عليه «مُموّل»',
      bottom: AppButton('احجز · ${iqd(total)}', onPressed: () => _book(total)),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('المحافظة'),
              chips(
                s.settings.governorates.toList(),
                _gov,
                (v) => setState(() => _gov = v),
              ),
              const SizedBox(height: 14),
              const FieldLabel('الصنف'),
              chips(
                s.settings.categories.toList(),
                _cat,
                (v) => setState(() => _cat = v),
              ),
              const SizedBox(height: 14),
              const FieldLabel('المدة'),
              chips(
                [for (final n in _unitOptions) _unitLabel(n)],
                _unitLabel(_units),
                (v) => setState(
                  () => _units = _unitOptions.firstWhere(
                    (n) => _unitLabel(n) == v,
                  ),
                ),
              ),
              if (widget.slot == AdSlot.homeBanner) ...[
                const SizedBox(height: 14),
                LabeledField(
                  label: 'نص البانر',
                  controller: _text,
                  hint: 'مثلاً: كل الأحذية خصم 20%',
                ),
                const SizedBox(height: 10),
                UploadBox(
                  label: 'ارفع صورة البانر',
                  done: _image != null,
                  onTap: () async {
                    final path = await pickPhoto(camera: false);
                    if (path != null && mounted) setState(() => _image = path);
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                StateCard(
                  icon: AppIcon.alert,
                  tint: AppColors.dangerBg,
                  tone: AppColors.danger,
                  title: _error!,
                  body: const TextSpan(
                    text: 'ممنوع رقم تلفون أو رابط أو حساب أو غرض ممنوع بالإعلان.',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TintedNote(
                'المبلغ ينحجز من رصيدك هسه، والمشرف يراجع الإعلان قبل ما يطلع. إذا انرفض يرجعلك كامل.',
                bg: AppColors.warnBg,
                fg: AppColors.warnText,
                icon: AppIcon.lock,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
