import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../live/presentation/widgets/live_sheets.dart';
import '../../offers/presentation/widgets/offer_widgets.dart';

/// 28 · «حسابي» tab. Mock profile until the account API lands.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void soon() => context.push(Routes.comingSoon);
    Widget group(List<Widget> rows) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: AppCard(
        insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                decoration: i == rows.length - 1
                    ? null
                    : const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                child: rows[i],
              ),
          ],
        ),
      ),
    );
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
                          'ع',
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
                            'أبو علي',
                            style: AppText.strong.copyWith(
                              fontSize: 18,
                              height: AppText.lh(18),
                              color: AppColors.white,
                            ),
                          ),
                          const Text(
                            '+964 770 ••• 4567',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
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
                group([
                  _Item(
                    AppIcon.pin,
                    'المحافظة والمنطقة',
                    'بغداد · الكرادة',
                    soon,
                  ),
                  _Item(AppIcon.bell, 'الإشعارات', 'مفعّلة', soon),
                  _Item(AppIcon.sparkles, 'الوضع الليلي', 'تلقائي', soon),
                  _Item(AppIcon.text, 'حجم الخط', 'كبير', soon),
                ]),
                group([
                  _Item(AppIcon.lock, 'الصفحات المحظورة', '2', soon),
                  _Item(
                    AppIcon.shieldCheck,
                    'سياسة الخصوصية',
                    '',
                    () => context.push(Routes.privacy),
                  ),
                  _Item(AppIcon.clipboard, 'الشروط', '', soon),
                  _Item(AppIcon.chat, 'تواصل ويانا', '', soon),
                ]),
                group([
                  _Item(
                    AppIcon.refresh,
                    'سجّل خروج',
                    '',
                    () => context.go(Routes.login),
                  ),
                  _Item(
                    AppIcon.trash,
                    'احذف حسابي',
                    '',
                    () => context.push(Routes.deleteAccount),
                    danger: true,
                  ),
                ]),
                const SizedBox(height: 10),
                const Text(
                  'دوّرلي v1.0.0',
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
                NavTab.notifications => context.go(Routes.notifications),
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

class _Item extends StatelessWidget {
  const _Item(
    this.icon,
    this.label,
    this.value,
    this.onTap, {
    this.danger = false,
  });
  final AppIcon icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          AppSvgIcon(
            icon,
            color: danger ? const Color(0xFFB42318) : AppColors.blue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: danger ? AppColors.danger : AppColors.navy,
              ),
            ),
          ),
          if (value.isNotEmpty) ...[
            Text(value, style: AppText.muted),
            const SizedBox(width: 12),
          ],
          const AppSvgIcon(
            AppIcon.chevronLeft,
            color: AppColors.checkOff,
            size: 18,
          ),
        ],
      ),
    ),
  );
}

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
                      style: const TextStyle(
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
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool sheet = true;
  final code = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  child: const AppCard(
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
                      color: Color(0xFFB42318),
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
                const Text(
                  'ما نكدر نرجعه. لازم تسكر طلبك المفتوح أول.',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
                const SizedBox(height: 14),
                const AppCard(
                  flat: true,
                  color: AppColors.warnBg,
                  padding: 12,
                  child: Text(
                    'عندك طلب «عطر عود» بالطريق. أكد الاستلام أو ألغيه أول.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.502222,
                      color: AppColors.warnText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('اكتب كود التأكيد اللي وصلك', style: AppText.label),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
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
                const AppButton(
                  'إي، احذف نهائياً',
                  variant: AppButtonVariant.danger,
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
