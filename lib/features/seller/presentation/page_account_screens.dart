import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/role/app_role.dart';
import '../../../core/router/routes.dart';
import '../../../core/settings/display_settings.dart';
import '../../../core/widgets/theme_mode_row.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toggle.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/widgets/state_card.dart';
import '../../auth/data/auth_providers.dart';
import '../../more/more_data.dart';
import '../../account/data/account_api.dart';
import '../../auth/data/session.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'widgets/seller_nav.dart';
import 'widgets/seller_widgets.dart';

const weekDays = [
  'السبت',
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
];

String _hour(int h) =>
    '${(h % 12 == 0 ? 12 : h % 12)}:00 ${h < 12 ? 'ص' : 'م'}';

/// «صفحتي» tab — page profile and every page-side setting.
class SellerAccountScreen extends ConsumerStatefulWidget {
  const SellerAccountScreen({super.key});

  @override
  ConsumerState<SellerAccountScreen> createState() =>
      _SellerAccountScreenState();
}

class _SellerAccountScreenState extends ConsumerState<SellerAccountScreen> {
  @override
  void initState() {
    super.initState();
    // Followers, rating and deals change while the app is open.
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    try {
      await ref.read(sellerProvider.notifier).refresh();
    } on Object {
      // Keep what we have; pull to refresh retries.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sellerProvider);
    final display = ref.watch(displaySettingsProvider);
    final displayCtl = ref.read(displaySettingsProvider.notifier);
    void go(String r) => context.push(r);
    return AppPage(
      title: 'صفحتي',
      showBack: false,
      onRefresh: _refresh,
      nav: const SellerNav(SellerTab.account),
      below: Row(
        children: [
          LetterAvatar(s.shopName, size: AppSize.avatar),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.shopName,
                  style: AppText.strong.copyWith(
                    fontSize: 18,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '${s.handle} · ${s.rating} · ${s.deals} صفقة',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.headerSub,
                  ),
                ),
              ],
            ),
          ),
          switch (s.status) {
            VerifyStatus.verified => PillTone.teal.pill('موثقة', check: true),
            VerifyStatus.rejected => PillTone.red.pill('مرفوضة'),
            _ => PillTone.gold.pill('مراجعة'),
          },
        ],
      ),
      children: [
        Gap(
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    thousands(s.followerCount),
                    'متابعين',
                    color: AppColors.blue,
                  ),
                ),
                Expanded(child: StatTile('${s.rating}', 'التقييم')),
                Expanded(child: StatTile('${s.deals}', 'صفقة')),
              ],
            ),
          ),
        ),
        SettingsGroup([
          SettingsRow(
            AppIcon.barChart,
            'التقارير والطلبات',
            onTap: () => go(Routes.sellerReports),
          ),
          SettingsRow(
            AppIcon.bell,
            'الإشعارات',
            value: '${s.notices.length}',
            onTap: () => go(Routes.sellerNotifications),
          ),
          SettingsRow(
            AppIcon.pencil,
            'إعدادات الصفحة',
            onTap: () => go(Routes.sellerSettings),
          ),
          SettingsRow(
            AppIcon.truck,
            'المناديب',
            onTap: () => go(Routes.sellerCouriers),
          ),
          SettingsRow(
            AppIcon.chartLine,
            'روّج لصفحتك',
            onTap: () => go(Routes.sellerAds),
          ),
          SettingsRow(
            AppIcon.image,
            'إعلاناتي',
            value: '${s.ads.length}',
            onTap: () => go(Routes.sellerMyAds),
          ),
          SettingsRow(
            AppIcon.star,
            'التقييمات',
            value: '${s.rating}',
            onTap: () => go(Routes.sellerRating),
          ),
        ]),
        SettingsGroup([
          SettingsRow(
            AppIcon.triangle,
            'حالة صفحتك',
            value: '${s.marks.length}',
            onTap: () => go(Routes.sellerStanding),
          ),
          SettingsRow(
            AppIcon.verified,
            'التوثيق',
            onTap: () => go(sellerEntryRoute(s.status)),
          ),
          const ThemeModeRow(),
          SettingsRow(
            AppIcon.text,
            'حجم الخط',
            value: display.font.label,
            onTap: displayCtl.nextFont,
          ),
        ]),
        SettingsGroup([
          SettingsRow(
            AppIcon.clipboard,
            'الشروط',
            onTap: () => go(Routes.terms),
          ),
          SettingsRow(
            AppIcon.shieldCheck,
            'سياسة الخصوصية',
            onTap: () => go(Routes.privacy),
          ),
          SettingsRow(
            AppIcon.chat,
            'تواصل ويانا',
            onTap: () => go(Routes.contact),
          ),
        ]),
        SettingsGroup([
          SettingsRow(
            AppIcon.refresh,
            'سجّل خروج',
            onTap: () async {
              await signOut(ref);
              if (context.mounted) context.go(Routes.login);
            },
          ),
          SettingsRow(
            AppIcon.trash,
            'احذف حساب الصفحة',
            danger: true,
            onTap: () => go(Routes.sellerDelete),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'دوّرلي للصفحات v1.0.2',
          textAlign: TextAlign.center,
          style: AppText.muted,
        ),
      ],
    );
  }
}

/// 48 · page settings.
class SellerSettingsScreen extends ConsumerStatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  ConsumerState<SellerSettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SellerSettingsScreen> {
  late PageSettings _s = ref.read(sellerProvider).settings;

  Set<T> _flip<T>(Set<T> s, T v) =>
      s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  Future<void> _pickHour(bool from) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: from ? _s.from : _s.to, minute: 0),
    );
    if (t != null) {
      setState(
        () => _s = from ? _s.copyWith(from: t.hour) : _s.copyWith(to: t.hour),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final govs = ref.watch(governoratesProvider).value ?? const <String>[];
    Widget box(String label, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: InputShell(
          child: Text(label, style: AppText.body.copyWith(fontSize: 15)),
        ),
      ),
    );
    return AppPage(
      title: 'إعدادات الصفحة',
      onBack: () => popOr(context, Routes.sellerAccount),
      bottom: AppButton(
        'احفظ',
        onPressed: () {
          ref.read(sellerProvider.notifier).saveSettings(_s);
          showAppToast(context, 'انحفظت الإعدادات');
          popOr(context, Routes.sellerAccount);
        },
      ),
      children: [
        SettingsGroup([
          SettingsRow(
            null,
            'استلام الطلبات',
            sub: _s.receiving
                ? 'مفعّل · طفّيه حتى توقف الطلبات مؤقتاً'
                : 'متوقف · ما توصلك طلبات جديدة',
            trailing: AppToggle(
              on: _s.receiving,
              onTap: () =>
                  setState(() => _s = _s.copyWith(receiving: !_s.receiving)),
            ),
          ),
          SettingsRow(
            null,
            'صوت الإشعار',
            sub: _s.sound ? 'نغمة دوّرلي' : 'صامت',
            trailing: AppToggle(
              on: _s.sound,
              onTap: () => setState(() => _s = _s.copyWith(sound: !_s.sound)),
            ),
          ),
        ]),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('شتبيع؟', style: AppText.strong),
                const SizedBox(height: 10),
                ChipPicker(
                  options: [
                    for (final c in ref.watch(catalogCategoriesProvider))
                      c.name,
                  ],
                  selected: _s.categories,
                  limit: 4,
                  categoryKeyOf: ref.watch(catalogCategoriesProvider).slugOf,
                  onToggle: (v) => setState(
                    () => _s = _s.copyWith(categories: _flip(_s.categories, v)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('توصل لوين؟', style: AppText.strong),
                const SizedBox(height: 10),
                ChipPicker(
                  options: govs,
                  selected: _s.governorates,
                  limit: 4,
                  onToggle: (v) => setState(
                    () => _s = _s.copyWith(
                      governorates: _flip(_s.governorates, v),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ساعات الشغل', style: AppText.strong),
                const SizedBox(height: 4),
                Text(
                  'برا هالوقت ما توصلك إشعارات، والطلبات تبقى بالصندوق',
                  style: AppText.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    box('من ${_hour(_s.from)}', () => _pickHour(true)),
                    const SizedBox(width: 10),
                    box('لحد ${_hour(_s.to)}', () => _pickHour(false)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (i, d) in weekDays.indexed)
                      AppChip(
                        d,
                        selected: _s.days.contains(i),
                        onTap: () => setState(
                          () => _s = _s.copyWith(days: _flip(_s.days, i)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Page notifications inbox; each opens its screen.
class SellerNotificationsScreen extends ConsumerWidget {
  const SellerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(sellerProvider).notices;
    return AppPage(
      title: 'الإشعارات',
      children: [
        SettingsGroup([
          for (final x in n)
            SettingsRow(
              AppIcon.bell,
              x.title,
              sub: '${x.body} · ${x.ago}',
              onTap: () => context.push(x.route),
            ),
        ]),
      ],
    );
  }
}

/// 24 · marks, warnings, suspension.
class SellerStandingScreen extends ConsumerWidget {
  const SellerStandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final marks = s.marks.where((m) => m.kind == MarkKind.mark).length;
    final suspended = marks >= 3;
    return AppPage(
      title: 'حالة صفحتك',
      onBack: () => popOr(context, Routes.sellerAccount),
      bottom: AppButton(
        'اعترض على علامة',
        variant: AppButtonVariant.ghost,
        onPressed: () => context.push(
          Routes.sellerAppeal(
            s.marks.lastWhere((m) => m.kind == MarkKind.mark).id,
          ),
        ),
      ),
      children: [
        Gap(
          suspended
              ? BannerCard(
                  icon: AppIcon.ban,
                  title: 'صفحتك موقوفة 7 أيام',
                  body: '3 علامات «ما ردت» خلال 30 يوم · ترجع 26/10/2026',
                )
              : BannerCard(
                  icon: AppIcon.shieldCheck,
                  title: 'صفحتك شغالة',
                  body: '$marks علامات خلال 30 يوم · 3 علامات = إيقاف 7 أيام',
                  bg: PillTone.teal.bg,
                  tile: const Color(0xFF0B6E66),
                  fg: PillTone.teal.fg,
                ),
        ),
        Gap(
          AppCard(
            insets: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('العلامات والإنذارات', style: AppText.strong),
                for (final m in s.marks)
                  SettingsRow(
                    m.kind == MarkKind.mark ? AppIcon.clock : AppIcon.image,
                    m.title,
                    sub: m.sub,
                    onTap: m.kind == MarkKind.mark
                        ? () => context.push(Routes.sellerAppeal(m.id))
                        : null,
                    trailing: s.appealed.contains(m.id)
                        ? PillTone.gold.pill('اعتراض')
                        : m.kind == MarkKind.mark
                        ? PillTone.red.pill('علامة')
                        : PillTone.gold.pill('مراجعة'),
                  ),
              ],
            ),
          ),
        ),
        Gap(
          TintedNote(
            'الشكوى الثانية المؤكدة = إيقاف مؤقت، والثالثة = حظر نهائي.${suspended ? ' إعلاناتك موقفة هسه.' : ''}',
            bg: AppColors.warnBg,
            fg: AppColors.warnText,
          ),
        ),
      ],
    );
  }
}

/// 24b · appeal a mark (also used for a rejected verification).
class SellerAppealScreen extends ConsumerStatefulWidget {
  const SellerAppealScreen({super.key, required this.markId});
  final String markId;

  @override
  ConsumerState<SellerAppealScreen> createState() => _AppealState();
}

class _AppealState extends ConsumerState<SellerAppealScreen> {
  final _text = TextEditingController();
  bool _photo = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sellerProvider);
    final m = s.marks.where((x) => x.id == widget.markId).firstOrNull;
    final sent = s.appealed.contains(widget.markId);
    final title = m == null ? 'اعترض على رفض التوثيق' : 'اعترض على علامة';
    final sub = m == null ? s.handle : '«${m.title}» · ${m.sub}';
    return AppPage(
      title: title,
      subtitle: sub,
      children: [
        if (!sent)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: 'شصار؟',
                  controller: _text,
                  lines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                const FieldLabel('دليل'),
                UploadBox(
                  label: 'ارفع صورة (غطّي الأرقام)',
                  done: _photo,
                  onTap: () => setState(() => _photo = !_photo),
                ),
                const SizedBox(height: 14),
                AppButton(
                  'دز الاعتراض',
                  variant: _text.text.trim().length < 10
                      ? AppButtonVariant.disabled
                      : AppButtonVariant.primary,
                  onPressed: _text.text.trim().length < 10
                      ? null
                      : () async {
                          await ref
                              .read(sellerProvider.notifier)
                              .appeal(widget.markId, _text.text.trim());
                          if (context.mounted) {
                            showAppToast(context, 'انرسل اعتراضك');
                          }
                        },
                ),
              ],
            ),
          ),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('رقم المتابعة', style: AppText.strong),
                    const Spacer(),
                    Text(
                      'APL-4471',
                      textDirection: TextDirection.ltr,
                      style: AppText.number.copyWith(color: AppColors.blue),
                    ),
                  ],
                ),
                StatusStep('انفتح', sent ? 'هسه' : 'بعد ما تدز', sent),
                StatusStep('قيد المراجعة', 'الإنذار متجمّد', sent),
                StatusStep('انحسم', 'خلال ${s.config.appealHours} ساعة', false),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Timeline dot + title + sub (24b, 50).
class StatusStep extends StatelessWidget {
  const StatusStep(this.title, this.sub, this.done, {super.key});
  final String title;
  final String sub;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.blue : AppColors.surface,
            border: Border.all(color: AppColors.blue, width: 2),
          ),
          alignment: Alignment.center,
          child: done
              ? const AppSvgIcon(
                  AppIcon.check,
                  color: AppColors.white,
                  size: 13,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.strong),
            Text(sub, style: AppText.muted),
          ],
        ),
      ],
    ),
  );
}

/// 30b · delete the page account (open order + balance warning, OTP).
class SellerDeleteScreen extends ConsumerStatefulWidget {
  const SellerDeleteScreen({super.key});

  @override
  ConsumerState<SellerDeleteScreen> createState() => _DeleteState();
}

class _DeleteState extends ConsumerState<SellerDeleteScreen> {
  static const _codeLength = 6;
  final _code = TextEditingController();
  String? _devCode;

  @override
  void initState() {
    super.initState();
    ref.read(accountApiProvider).requestDeleteCode().then((c) {
      if (mounted) setState(() => _devCode = c);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sellerProvider);
    final open = s.offers
        .where((o) => o.state == OfferState.chosen)
        .firstOrNull;
    final ok = open == null && _code.text.length == _codeLength;
    return Scaffold(
      backgroundColor: const Color(0x8C070E1F),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          child: AppSheet(
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon(
                    AppIcon.trash,
                    color: AppColors.danger,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'تحذف حساب «${s.shopName}»؟',
                textAlign: TextAlign.center,
                style: AppText.strong.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 6),
              Text(
                'تنحذف الصفحة وعروضها وصورها. الحركات المالية تبقى بدون اسم.',
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
              if (open != null) ...[
                const SizedBox(height: 10),
                StateCard(
                  icon: AppIcon.alert,
                  tint: AppColors.warnBg,
                  tone: AppColors.warn,
                  title: 'عندك طلب مفتوح ويا زبون',
                  body: TextSpan(
                    text:
                        'سكّره أول. ورصيدك ${iqd(s.balance)}، اطلب استرجاعه قبل الحذف.',
                  ),
                  action: 'شوف الطلب',
                  actionVariant: AppButtonVariant.ghost,
                  onAction: () => context.push(Routes.sellerChosen(open.id)),
                ),
              ],
              const SizedBox(height: 14),
              LabeledField(
                label: _devCode == null
                    ? 'كود التأكيد'
                    : 'كود التأكيد ($_devCode)',
                controller: _code,
                ltr: true,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppButton(
                'احذف نهائياً',
                variant: ok
                    ? AppButtonVariant.danger
                    : AppButtonVariant.disabled,
                onPressed: ok
                    ? () async {
                        await ref.read(accountApiProvider).delete(_code.text);
                        ref.read(sellerProvider.notifier).reset();
                        ref.read(appRoleProvider.notifier).set(AppRole.buyer);
                        if (context.mounted) context.go(Routes.onboarding);
                      }
                    : null,
              ),
              const SizedBox(height: 10),
              AppButton(
                'لا، رجعني',
                variant: AppButtonVariant.ghost,
                onPressed: () => popOr(context, Routes.sellerAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
