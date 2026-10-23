import 'package:flutter/material.dart';

import '../../../core/widgets/radio_row.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/media.dart';
import '../../../core/api/picker.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/loading_block.dart';
import '../../orders/data/orders_providers.dart';
import '../data/standing_providers.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../offers/presentation/widgets/offer_widgets.dart';

const _red = Color(0xFF7A1A10);

Widget _gap(Widget w) =>
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: w);

/// 46 (suspended) / 46b (banned): why, appeal, appeal status.
class StandingScreen extends ConsumerWidget {
  const StandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(standingProvider).value;
    if (st == null) {
      return const Scaffold(body: LoadingBlock());
    }
    final banned = st.permanent;
    final strikes = st.strikes;
    final appeal = ref.watch(myDisputesProvider).value?.firstOrNull;
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
                          color: AppColors.dangerFill,
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
                            : st.bannedUntil == null
                            ? 'عندك ${strikes.length} من ${st.strikesForBan} مخالفات'
                            : 'حسابك موقوف لحد ${dayMonth(st.bannedUntil!)}/${st.bannedUntil!.year}',
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
                            : '${st.strikesForBan} مخالفات مؤكدة توقف النشر مؤقتاً',
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
                      for (var i = 0; i < strikes.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: i == strikes.length - 1
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
                              AppSvgIcon(
                                AppIcon.alert,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(strikes[i].reason, style: AppText.strong),
                                    Text(
                                      strikes[i].frozen
                                          ? '${dayMonth(strikes[i].at)} · متجمّد'
                                          : dayMonth(strikes[i].at),
                                      style: AppText.muted,
                                    ),
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
                    if (appeal != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push(Routes.disputeStatusOf(appeal.id)),
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
                                Pill(
                                  _statusLabel(appeal.status),
                                  bg: AppColors.warnBg,
                                  fg: AppColors.warn,
                                ),
                                const SizedBox(width: 12),
                                Text('اعتراضك', style: AppText.muted),
                                const Spacer(),
                                Text(
                                  appeal.trackNo,
                                  textDirection: TextDirection.ltr,
                                  style: AppText.strong.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              appeal.decided
                                  ? appeal.decision ?? ''
                                  : 'القرار لحد ${dayTimeLabel(appeal.decideBy)}',
                              style: AppText.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ],
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

String _statusLabel(String status) => switch (status) {
  'accepted' => 'انقبل',
  'rejected' => 'انرفض',
  _ => 'قيد المراجعة',
};

/// 49 · new dispute.
class DisputeNewScreen extends ConsumerStatefulWidget {
  const DisputeNewScreen({super.key, this.orderId});

  /// Order the dispute is about (null for an appeal on my standing).
  final String? orderId;

  @override
  ConsumerState<DisputeNewScreen> createState() => _DisputeNewScreenState();
}

class _DisputeNewScreenState extends ConsumerState<DisputeNewScreen> {
  static const _types = [
    ('الصفحة ما ردت', 'noReply'),
    ('الغرض ما وصل', 'notDelivered'),
    ('بلاغ كاذب عليّ', 'fakeReport'),
    ('اعتراض على إنذار', 'strikeAppeal'),
  ];
  static const _minText = 10;
  late int type = widget.orderId == null ? _types.length - 1 : 1;
  final text = TextEditingController();
  final _photos = <String>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    text.addListener(() => setState(() {}));
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final keys = [for (final p in _photos) ?await uploadImage(api, p, 'disputes')];
      final d = await api.post<Map<String, dynamic>>('/api/v1/disputes', {
        'orderId': widget.orderId,
        'type': _types[type].$2,
        'text': text.text.trim(),
        'photos': keys,
      });
      ref.invalidate(myDisputesProvider);
      if (mounted) context.pushReplacement(Routes.disputeStatusOf(d.s('id')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderId == null
        ? null
        : ref.watch(orderProvider(widget.orderId!)).value;
    final ok = text.text.trim().length >= _minText && !_busy;
    return Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: 'اعتراض جديد',
            subtitle: Text(
              order == null
                  ? 'اعتراض واحد مفتوح لكل قرار'
                  : '#${order.orderNo} · اعتراض واحد مفتوح لكل طلب',
            ),
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
                    child: RadioRow(
                      label: _types[i].$1,
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final p in _photos)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AppImage(p, width: 76, height: 76, fit: BoxFit.cover),
                      ),
                    GestureDetector(
                      onTap: () async {
                        final p = await pickPhoto(camera: false);
                        if (p != null && mounted) setState(() => _photos.add(p));
                      },
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
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
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
                  variant: ok ? AppButtonVariant.primary : AppButtonVariant.disabled,
                  onPressed: ok ? _send : null,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

/// 50 · dispute status timeline.
class DisputeStatusScreen extends ConsumerWidget {
  const DisputeStatusScreen({super.key, this.id});

  /// Dispute to show; null shows my latest one.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = id == null
        ? ref.watch(myDisputesProvider).value?.firstOrNull
        : ref.watch(disputeProvider(id!)).value;
    if (d == null) return const Scaffold(body: LoadingBlock());
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
              subtitle: Text('رقم المتابعة ${d.trackNo}'),
              onBack: () => context.pop(),
            ),
            _gap(
              AppCard(
                child: Column(
                  children: [
                    step('انفتح', dayTimeLabel(d.createdAt), true),
                    step('قيد المراجعة', 'فريقنا دا يشوف الأدلة', true),
                    step(
                      d.decided ? _statusLabel(d.status) : 'انحسم',
                      d.decided
                          ? d.decision ?? ''
                          : 'لحد ${dayTimeLabel(d.decideBy)}',
                      d.decided,
                    ),
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
                    AppSvgIcon(
                      AppIcon.lock,
                      color: AppColors.warn,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pill(
                          'انقبل: انشال الإنذار',
                          bg: AppColors.tealBg,
                          fg: AppColors.teal,
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
                onPressed: () => context.push(
                  d.orderId == null ? Routes.disputeNew : Routes.disputeFor(d.orderId!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
