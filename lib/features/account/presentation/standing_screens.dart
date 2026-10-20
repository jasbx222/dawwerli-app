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
import '../../offers/presentation/widgets/offer_widgets.dart';
import '../../report/presentation/report_screen.dart';

const _red = Color(0xFF7A1A10);

// Mock strikes until the account-standing API lands.
const _strikes = [
  ('اخترت عرض وما رديت على الصفحة', '03/10 · #DW-19102'),
  ('رفضت الاستلام بدون سبب', '11/10 · #DW-19733'),
  ('اخترت عرض وما رديت على الصفحة', '18/10 · #DW-20390'),
];

Widget _gap(Widget w) =>
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: w);

/// 46 (suspended) / 46b (banned): why, appeal, appeal status.
class StandingScreen extends StatelessWidget {
  const StandingScreen({super.key, this.banned = false});
  final bool banned;

  @override
  Widget build(BuildContext context) => Scaffold(
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
              const AppHeader(title: 'حسابك', showBack: false),
              _gap(
                AppCard(
                  flat: true,
                  color: AppColors.dangerBg,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB42318),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const AppSvgIcon(
                          AppIcon.lock,
                          color: AppColors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        banned
                            ? 'حسابك موقوف نهائياً'
                            : 'حسابك موقوف لحد 26/10/2026',
                        textAlign: TextAlign.center,
                        style: AppText.strong.copyWith(
                          fontSize: 19,
                          height: AppText.lh(19),
                          color: _red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banned
                            ? 'ثاني إيقاف خلال الحساب'
                            : '3 مخالفات مؤكدة خلال 30 يوم · إيقاف أسبوع',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _gap(
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ليش؟', style: AppText.strong),
                      for (var i = 0; i < _strikes.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: i == _strikes.length - 1
                              ? null
                              : BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                ),
                          child: Row(
                            children: [
                              const AppSvgIcon(
                                AppIcon.alert,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_strikes[i].$1, style: AppText.strong),
                                    Text(_strikes[i].$2, style: AppText.muted),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _gap(
                AppCard(
                  flat: true,
                  color: AppColors.warnBg,
                  child: Text(
                    banned
                        ? 'هذا ثاني إيقاف، فصار نهائي. تكدر تتصفح بس ما تكدر تنشر.'
                        : 'تكدر تتصفح وتشوف طلباتك القديمة، بس ما تكدر تنشر لحد ما يخلص الإيقاف. الإيقاف الثاني يصير نهائي.',
                    style: AppText.muted.copyWith(color: AppColors.warnText),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      'اعترض على القرار',
                      icon: AppIcon.flag,
                      onPressed: () => context.push(Routes.disputeNew),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push(Routes.disputeStatus),
                      child: AppCard(
                        insets: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Pill(
                                  'قيد المراجعة',
                                  bg: AppColors.warnBg,
                                  fg: AppColors.warn,
                                ),
                                const SizedBox(width: 12),
                                Text('اعتراضك', style: AppText.muted),
                                const Spacer(),
                                Text(
                                  'APL-5102',
                                  textDirection: TextDirection.ltr,
                                  style: AppText.strong.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('القرار خلال 48 ساعة', style: AppText.muted),
                          ],
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

/// 49 · new dispute.
class DisputeNewScreen extends StatefulWidget {
  const DisputeNewScreen({super.key});

  @override
  State<DisputeNewScreen> createState() => _DisputeNewScreenState();
}

class _DisputeNewScreenState extends State<DisputeNewScreen> {
  static const _types = [
    'الصفحة ما ردت',
    'الغرض ما وصل',
    'بلاغ كاذب عليّ',
    'اعتراض على إنذار',
  ];
  int type = 3;
  final text = TextEditingController(
    text: 'رديت على الصفحة بالواتساب بنفس اليوم، وعندي صورة المحادثة',
  );

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: 'اعتراض جديد',
            subtitle: const Text('#DW-20481 · اعتراض واحد مفتوح لكل طلب'),
            onBack: () => context.pop(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('نوع الاعتراض', style: AppText.label),
                const SizedBox(height: 8),
                for (var i = 0; i < _types.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ReportRadio(
                      label: _types[i],
                      on: i == type,
                      onTap: () => setState(() => type = i),
                    ),
                  ),
                const SizedBox(height: 10),
                Text('احجيلنا شصار', style: AppText.label),
                const SizedBox(height: 8),
                Container(
                  height: 90,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: TextField(
                    controller: text,
                    maxLines: null,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('صور (اختياري)', style: AppText.label),
                const SizedBox(height: 8),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DashedCard(
                    radius: 16,
                    padding: 0,
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: Center(
                        child: AppSvgIcon(
                          AppIcon.camera,
                          color: AppColors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: AppSvgIcon(
                          AppIcon.alert,
                          color: AppColors.danger,
                          size: 13,
                          strokeWidth: 2.1,
                        ),
                      ),
                      TextSpan(
                        text: ' غطّي رقمك وأرقام غيرك بالصورة قبل لا ترفعها',
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  flat: true,
                  color: AppColors.blueTint,
                  child: Text(
                    'الإنذار يتجمّد لحد ما نقرر، والقرار خلال 48 ساعة.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.502222,
                      color: AppColors.infoText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  'دز الاعتراض',
                  onPressed: () =>
                      context.pushReplacement(Routes.disputeStatus),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 50 · dispute status timeline.
class DisputeStatusScreen extends StatelessWidget {
  const DisputeStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget step(String t, String sub, bool done) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.blue : AppColors.surface,
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            alignment: Alignment.center,
            child: done
                ? const AppSvgIcon(
                    AppIcon.verified,
                    color: AppColors.white,
                    size: 14,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: AppText.strong),
              Text(sub, style: AppText.muted),
            ],
          ),
        ],
      ),
    );
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: 'اعتراضك',
              subtitle: const Text('رقم المتابعة CMP-30988'),
              onBack: () => context.pop(),
            ),
            _gap(
              AppCard(
                child: Column(
                  children: [
                    step('انفتح', '19/10 · 10:05 م', true),
                    step('قيد المراجعة', 'فريقنا دا يشوف الأدلة', true),
                    step('انحسم', 'خلال 48 ساعة · لحد 21/10 10:05 م', false),
                  ],
                ),
              ),
            ),
            _gap(
              AppCard(
                flat: true,
                color: AppColors.warnBg,
                child: Row(
                  children: [
                    const AppSvgIcon(
                      AppIcon.lock,
                      color: AppColors.warn,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(
                              text: 'الإنذار متجمّد ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: AppSvgIcon(
                                AppIcon.snowflake,
                                color: AppColors.warnText,
                                size: 13,
                                strokeWidth: 2.1,
                              ),
                            ),
                            TextSpan(
                              text: '\nما ينحسب عليك لحد ما يطلع القرار',
                            ),
                          ],
                        ),
                        style: AppText.muted.copyWith(
                          color: AppColors.warnText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _gap(
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('القرار', style: AppText.strong),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pill(
                          'انقبل: انشال الإنذار',
                          bg: Color(0xFFCCFBF1),
                          fg: Color(0xFF0B6E66),
                          icon: AppIcon.check,
                        ),
                        Pill(
                          'انرفض: الإنذار يبقى',
                          bg: AppColors.dangerBg,
                          fg: AppColors.danger,
                          icon: AppIcon.x,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('نبلغك بإشعار أول ما ينحسم', style: AppText.muted),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                'أضيف دليل',
                variant: AppButtonVariant.ghost,
                onPressed: () => context.push(Routes.disputeNew),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
