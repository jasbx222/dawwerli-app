import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/catalog.dart';
import '../../core/utils/format.dart';
import '../live/data/live_providers.dart';
import '../post/data/post_providers.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/full_state.dart';
import '../offers/presentation/widgets/offer_widgets.dart';

void _back(BuildContext c) => c.canPop() ? c.pop() : c.go(Routes.home);

/// 31 · offline with a queued draft.
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftTitle = ref.watch(draftProvider).description.split('،').first.trim();
    return FullStateScreen(
    header: 'دوّرلي',
    icon: AppIcon.wifiOff,
    titleIcon: AppIcon.wifiOffSmall,
    title: 'النت فاصل',
    body: 'مسودتك محفوظة على الموبايل، وراح تنرسل وحدها أول ما يرجع النت.',
    extra: draftTitle.isEmpty ? null : Padding(
      padding: const EdgeInsets.only(top: 20),
      child: AppCard(
        child: Row(
          children: [
            Pill('بالانتظار', bg: AppColors.warnBg, fg: AppColors.warn),
            const SizedBox(width: 12),
            Text('$draftTitle · مسودة', style: AppText.strong),
          ],
        ),
      ),
    ),
    action: 'جرّب مرة ثانية',
    onAction: () => _back(context),
    onBack: () => _back(context),
  );
  }
}

/// 34 · offers failed to load.
class OffersErrorScreen extends StatelessWidget {
  const OffersErrorScreen({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FullStateScreen(
    header: 'العروض',
    icon: AppIcon.alert,
    titleIcon: AppIcon.smile,
    title: 'صار خلل بسيط',
    body: 'ما كدرنا نجيب العروض هسه. لا تخاف، طلبك شغال والعروض محفوظة.',
    action: 'حدّث الصفحة',
    onAction: onRetry,
    onBack: () => _back(context),
  );
}

/// 35 · request closed after 24h with no offers.
class NoOffersScreen extends ConsumerWidget {
  const NoOffersScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(liveRequestProvider(requestId)).value;
    final suggested = r?.suggestedPrice;
    return FullStateScreen(
    header: r?.title ?? '',
    icon: AppIcon.clock,
    title: 'ما لكينا عروض هالمرة',
    body: 'مرّت 24 ساعة بدون عروض، فسكرنا الطلب. ما انخصم شي من أحد. جرب ترفع السعر أو تغير الوصف.',
    extra: suggested == null ? null : Padding(
      padding: const EdgeInsets.only(top: 18),
      child: AppCard(
        flat: true,
        color: AppColors.warnBg,
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: OfferIcon.bulb.of(AppColors.warnText, 14),
              ),
              // Server suggestion from similar requests; hidden when there's none.
              TextSpan(
                text: ' أغلب الطلبات المشابهة انحلت بسعر حول ${thousands(suggested)} د.ع',
              ),
            ],
          ),
          style: AppText.muted.copyWith(color: AppColors.warnText),
        ),
      ),
    ),
    action: 'عدّل وانشر مرة ثانية',
    onAction: () => context.go(Routes.post),
    onBack: () => _back(context),
  );
  }
}

/// 36 · no pages for this category in the customer's governorate.
class NoPagesScreen extends ConsumerWidget {
  const NoPagesScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FullStateScreen(
    header: ref.watch(liveRequestProvider(requestId)).value?.title ?? '',
    icon: AppIcon.pin,
    title: 'ماكو صفحات بهالصنف حالياً',
    body: 'لحد هسه ما عدنا صفحات بهالصنف توصل لمحافظتك. سجلنا طلبك، ونبلغك أول ما تنضم صفحة.',
    action: 'بلغني',
    onAction: () => _back(context),
    onBack: () => _back(context),
  );
}

/// 37 · three open requests already.
class MaxOpenScreen extends ConsumerWidget {
  const MaxOpenScreen({super.key});

  static const _fallbackMax = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final max = (ref.watch(appConfigProvider).value?['maxOpenRequests'] as num?)?.toInt() ?? _fallbackMax;
    return FullStateScreen(
    header: 'انشر طلب',
    icon: AppIcon.lock,
    title: 'عندك $max طلبات مفتوحة',
    body: 'هذا الحد. سكّر طلب أو اختار عرض حتى تكدر تنشر طلب جديد.',
    extra: Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= max; i++) ...[
            if (i > 1) const SizedBox(width: 12),
            _DotPill('$i'),
          ],
        ],
      ),
    ),
    action: 'شوف طلباتي',
    onAction: () => context.go(Routes.myRequests),
    onBack: () => _back(context),
  );
  }
}

class _DotPill extends StatelessWidget {
  const _DotPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.tealBg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: AppText.lh(12),
            fontWeight: FontWeight.w700,
            color: AppColors.teal,
          ),
        ),
      ],
    ),
  );
}

/// 38 · forced update.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) => FullStateScreen(
    header: 'دوّرلي',
    icon: AppIcon.refresh,
    titleIcon: AppIcon.sparkle,
    title: 'أكو تحديث جديد',
    body: 'حدّث التطبيق حتى تكمل، النسخة القديمة ما تشتغل بعد.',
    action: 'حدّث هسه',
    onBack: () => _back(context),
  );
}
