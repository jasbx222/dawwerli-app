import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/settings/display_settings.dart';
import '../../../core/widgets/theme_mode_row.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/settings_row.dart';
import '../../live/presentation/widgets/live_sheets.dart';
import '../../more/more_data.dart';
import '../../orders/data/my_requests_provider.dart';
import '../../../core/api/api_config.dart';
import '../../auth/data/session.dart';
import '../data/account_api.dart';
import '../../store/data/store_data.dart';
import 'server_url_sheet.dart';
import '../../seller/data/seller_controller.dart';
import '../../offers/presentation/widgets/offer_widgets.dart';

/// 28 · «حسابي» tab (profile from GET /me).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(displaySettingsProvider);
    final displayCtl = ref.read(displaySettingsProvider.notifier);
    final region = ref.watch(regionProvider);
    final notifOn = ref.watch(notifPrefsProvider).values.where((v) => v).length;
    final blocked = ref.watch(blockedProvider).length;
    final favorites = ref.watch(favoritesProvider).length;
    final me = ref.watch(meProvider).value;
    final server = ref.watch(apiBaseUrlProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 18 + 70 + 24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: 'حسابي',
                  showBack: false,
                  below: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          me?.initial ?? '',
                          style: AppText.strong.copyWith(
                            fontSize: 24,
                            height: AppText.lh(24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me?.name ?? '',
                            style: AppText.strong.copyWith(
                              fontSize: 18,
                              height: AppText.lh(18),
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            me?.maskedPhone ?? '',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.headerSub,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Pill(
                        'صياد العروض',
                        bg: AppColors.goldSoft.withValues(alpha: .2),
                        fg: AppColors.goldSoft,
                        icon: AppIcon.trophy,
                      ),
                    ],
                  ),
                ),
                SettingsGroup([
                  _item(
                    AppIcon.heart,
                    'المفضلة',
                    favorites == 0 ? 'فارغة' : '$favorites منتج',
                    () => context.push(Routes.favorites),
                  ),
                  _item(
                    AppIcon.pin,
                    'المحافظة والمنطقة',
                    region.label,
                    () => context.push(Routes.region),
                  ),
                  _item(
                    AppIcon.bell,
                    'الإشعارات',
                    notifOn == 0 ? 'مطفية' : 'مفعّلة',
                    () => context.push(Routes.notificationSettings),
                  ),
                  const ThemeModeRow(),
                  _item(
                    AppIcon.text,
                    'حجم الخط',
                    display.font.label,
                    displayCtl.nextFont,
                  ),
                ]),
                SettingsGroup([
                  _item(
                    AppIcon.lock,
                    'الصفحات المحظورة',
                    blocked == 0 ? '' : '$blocked',
                    () => context.push(Routes.blocked),
                  ),
                  _item(
                    AppIcon.shieldCheck,
                    'سياسة الخصوصية',
                    '',
                    () => context.push(Routes.privacy),
                  ),
                  _item(
                    AppIcon.clipboard,
                    'الشروط',
                    '',
                    () => context.push(Routes.terms),
                  ),
                  _item(
                    AppIcon.chat,
                    'تواصل ويانا',
                    '',
                    () => context.push(Routes.contact),
                  ),
                  _item(
                    AppIcon.link,
                    'عنوان الخادم',
                    server,
                    () => ServerUrlSheet.show(context),
                  ),
                ]),
                SettingsGroup([
                  _item(
                    AppIcon.refresh,
                    'سجّل خروج',
                    '',
                    () async {
                      await signOut(ref);
                      if (context.mounted) context.go(Routes.login);
                    },
                  ),
                  _item(
                    AppIcon.trash,
                    'احذف حسابي',
                    '',
                    () => context.push(Routes.deleteAccount),
                    danger: true,
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'دوّرلي v1.0.2',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18 + MediaQuery.viewPaddingOf(context).bottom,
            child: AppBottomNav(
              current: NavTab.account,
              onTab: (t) => switch (t) {
                NavTab.home => context.go(Routes.home),
                NavTab.requests => context.go(Routes.myRequests),
                NavTab.pages => context.go(Routes.pages),
                NavTab.account => null,
              },
              onPost: () => context.push(Routes.post),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _item(
  AppIcon icon,
  String label,
  String value,
  VoidCallback onTap, {
  bool danger = false,
}) => SettingsRow(icon, label, value: value, onTap: onTap, danger: danger);

/// 29 · privacy policy.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    ('شنو نجمع؟', 'رقمك، اسمك، محافظتك ومنطقتك، وصور وتسجيلات طلباتك.'),
    ('منو يشوف رقمك؟', 'بس الصفحة اللي تختار عرضها، ولا أحد غيرها.'),
    ('الدفع', 'التطبيق ما يمسك فلوس. الدفع عند الاستلام بينك وبين الصفحة.'),
    ('الصور', 'تنحفظ بروابط موقعة ومؤقتة، وما تنعرض بالرئيسية.'),
    ('حذف الحساب', 'تكدر تحذفه من «حسابي»، ونمسح بياناتك الشخصية نهائياً.'),
    ('تواصل', 'privacy@dawwerli.iq'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: 'سياسة الخصوصية',
            subtitle: const Text('آخر تحديث 19/10/2026'),
            onBack: () => context.pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (t, b) in _sections) ...[
                    const SizedBox(height: 8),
                    Text(
                      t,
                      style: AppText.strong.copyWith(
                        fontSize: 15,
                        height: 1.85,
                      ),
                    ),
                    Text(
                      b,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.85,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 30 · delete account: what gets deleted + confirmation sheet.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  static const _codeLength = 6;
  bool sheet = true;
  final code = TextEditingController();
  String? _devCode;

  @override
  void initState() {
    super.initState();
    code.addListener(() => setState(() {}));
    ref.read(accountApiProvider).requestDeleteCode().then((c) {
      if (mounted) setState(() => _devCode = c);
    });
  }

  Future<void> _delete() async {
    await ref.read(accountApiProvider).delete(code.text.trim());
    ref.read(sellerProvider.notifier).reset();
    if (mounted) context.go(Routes.onboarding);
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = (ref.watch(myRequestsProvider).value ?? const <RequestSummary>[])
        .where((r) => r.status == 'selected')
        .firstOrNull;
    final ok = open == null && code.text.trim().length == _codeLength;
    return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          enabled: sheet,
          imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(title: 'احذف حسابي', onBack: () => context.pop()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: GestureDetector(
                  onTap: () => setState(() => sheet = true),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('شنو ينحذف؟', style: AppText.strong),
                        SizedBox(height: 6),
                        Text(
                          '• اسمك ورقمك\n• صور وتسجيلات طلباتك\n• إشعاراتك وأجهزتك\nالطلبات المالية تبقى بدون اسم',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.9,
                            color: AppColors.grey,
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
        if (sheet) ...[
          GestureDetector(
            onTap: () => setState(() => sheet = false),
            child: const ColoredBox(color: Color(0x8C070E1F)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
                    child: const AppSvgIcon(
                      AppIcon.trash,
                      color: AppColors.dangerFill,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'متأكد تحذف حسابك؟',
                  textAlign: TextAlign.center,
                  style: AppText.strong.copyWith(
                    fontSize: 19,
                    height: AppText.lh(19),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ما نكدر نرجعه. لازم تسكر طلبك المفتوح أول.',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
                if (open != null) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    flat: true,
                    color: AppColors.warnBg,
                    padding: 12,
                    child: Text(
                      'عندك طلب «${open.title}» بالطريق. أكد الاستلام أو ألغيه أول.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.502222,
                        color: AppColors.warnText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  _devCode == null
                      ? 'اكتب كود التأكيد اللي وصلك'
                      : 'اكتب كود التأكيد اللي وصلك ($_devCode)',
                  style: AppText.label,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.blue, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F1F4E9C), spreadRadius: 4),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: AppText.number.copyWith(
                        fontSize: 18,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        hintText: '_ _ _ _ _ _',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Blocked while an order is open (the warning above).
                AppButton(
                  'إي، احذف نهائياً',
                  variant: ok
                      ? AppButtonVariant.danger
                      : AppButtonVariant.disabled,
                  onPressed: ok ? _delete : null,
                ),
                const SizedBox(height: 10),
                AppButton(
                  'لا، رجعني',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
  }
}
