import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/picker.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/state_card.dart';
import '../../home/domain/sponsored_popup_ad.dart';
import '../../home/presentation/widgets/sponsored_popup.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'topup_sheet.dart';
import 'widgets/seller_widgets.dart';

/// Live per-day prices and popup timing (admin settings).
class AdPricing {
  const AdPricing({
    required this.sponsoredDaily,
    required this.durationSec,
    required this.intervalMin,
  });

  factory AdPricing.fromJson(Map<String, dynamic> j) => AdPricing(
    sponsoredDaily: j.i('sponsoredOffer'),
    durationSec: j.i('popupDurationSec'),
    intervalMin: j.i('popupIntervalMin'),
  );

  final int sponsoredDaily;
  final int durationSec;
  final int intervalMin;
}

/// GET /api/v1/pages/me/ads/pricing — always fresh, so a price change in the
/// dashboard shows up the next time the screen opens.
final adPricingProvider = FutureProvider.autoDispose<AdPricing>((ref) async {
  final j = await ref
      .read(apiClientProvider)
      .get<Map<String, dynamic>>('/api/v1/pages/me/ads/pricing');
  return AdPricing.fromJson(j);
});

/// Quick picks for the popup campaign length (days).
const sponsoredDayOptions = [1, 3, 7, 14, 30];

String daysLabel(int n) => switch (n) {
  1 => 'يوم',
  2 => 'يومين',
  <= 10 => '$n أيام',
  _ => '$n يوم',
};

/// Book a sponsored popup ad: days × daily price, title, text, image, preview.
class SponsoredAdBookScreen extends ConsumerStatefulWidget {
  const SponsoredAdBookScreen({super.key});

  @override
  ConsumerState<SponsoredAdBookScreen> createState() => _State();
}

class _State extends ConsumerState<SponsoredAdBookScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  late String _gov =
      ref.read(sellerProvider).settings.governorates.firstOrNull ?? '';
  late String _cat =
      ref.read(sellerProvider).settings.categories.firstOrNull ?? '';
  int _days = 7;
  String? _image;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  SponsoredPopupAd _previewAd() {
    final s = ref.read(sellerProvider);
    return SponsoredPopupAd(
      id: '',
      pageId: '',
      pageName: s.shopName,
      title: _title.text.trim().isEmpty ? 'عنوان إعلانك' : _title.text.trim(),
      headline: _text.text.trim(),
      image: _image ?? '',
      pageHandle: s.handle.replaceFirst('@', ''),
      pageVerified: true,
    );
  }

  void _preview(AdPricing p) {
    if (_image == null) {
      setState(() => _error = 'ارفع صورة الإعلان حتى تشوف المعاينة');
      return;
    }
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'معاينة',
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => SponsoredPopup(
        ad: _previewAd(),
        duration: Duration(seconds: p.durationSec),
        frozenAt: .35,
      ),
    );
  }

  Future<void> _book(int total) async {
    if (_busy) return;
    final s = ref.read(sellerProvider);
    final title = _title.text.trim();
    final text = _text.text.trim();
    final err = title.isEmpty
        ? 'اكتب عنوان الإعلان'
        : _image == null
        ? 'ارفع صورة الإعلان'
        : hasContact('$title $text')
        ? 'شيل الرقم أو الرابط أو @الحساب من النص'
        : null;
    setState(() => _error = err);
    if (err != null) return;
    if (s.balance < total) {
      TopupSheet.show(context);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(sellerProvider.notifier)
          .bookAd(
            slot: AdSlot.sponsoredOffer,
            title: title,
            headline: text,
            category: _cat,
            governorate: _gov,
            days: _days,
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
    final pricing = ref.watch(adPricingProvider);
    final p = pricing.value;
    final total = p == null ? null : p.sponsoredDaily * _days;
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
      title: 'إعلان مُموّل منبثق',
      subtitle: p == null
          ? 'ينكتب عليه «إعلان ممول»'
          : '${iqd(p.sponsoredDaily)} باليوم · ينكتب عليه «إعلان ممول»',
      bottom: AppButton(
        total == null ? 'احجز' : 'احجز · ${iqd(total)}',
        variant: total == null || _busy
            ? AppButtonVariant.disabled
            : AppButtonVariant.primary,
        onPressed: total == null ? null : () => _book(total),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (p != null)
                TintedNote(
                  'يطلع للزبون كنافذة بنص الشاشة ${p.durationSec} ثواني، '
                  'ويكدر يسدها بأي وقت. إعلان واحد كل ${p.intervalMin} دقايق '
                  'بالتناوب بين المعلنين.',
                  bg: AppColors.slotBg,
                  fg: AppColors.infoText,
                  icon: AppIcon.zap,
                ),
              if (pricing.hasError)
                StateCard(
                  icon: AppIcon.alert,
                  tint: AppColors.dangerBg,
                  tone: AppColors.danger,
                  title: 'ما كدرنا نجيب السعر',
                  body: const TextSpan(text: 'تأكد من الإنترنت وارجع جرب.'),
                  action: 'جرب مرة ثانية',
                  actionVariant: AppButtonVariant.ghost,
                  onAction: () => ref.invalidate(adPricingProvider),
                ),
              const SizedBox(height: 14),
              const FieldLabel('عدد الأيام'),
              chips(
                [for (final n in sponsoredDayOptions) daysLabel(n)],
                daysLabel(_days),
                (v) => setState(
                  () => _days = sponsoredDayOptions.firstWhere(
                    (n) => daysLabel(n) == v,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                key: const Key('sponsored-price'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p == null
                            ? 'نحسب السعر…'
                            : '${daysLabel(_days)} × ${iqd(p.sponsoredDaily)}',
                        style: AppText.muted,
                      ),
                    ),
                    Text(
                      total == null ? '—' : iqd(total),
                      style: AppText.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
              LabeledField(
                label: 'عنوان الإعلان',
                controller: _title,
                hint: 'مثلاً: تخفيضات الشتاء',
              ),
              const SizedBox(height: 10),
              LabeledField(
                label: 'نص قصير (اختياري)',
                controller: _text,
                hint: 'مثلاً: كل الجواكيت خصم 30%',
              ),
              const SizedBox(height: 10),
              UploadBox(
                label: 'ارفع صورة الإعلان',
                done: _image != null,
                onTap: () async {
                  final path = await pickPhoto(camera: false);
                  if (path != null && mounted) setState(() => _image = path);
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                'معاينة شكل الإعلان',
                variant: AppButtonVariant.ghost,
                onPressed: p == null ? null : () => _preview(p),
              ),
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
