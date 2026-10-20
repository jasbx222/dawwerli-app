import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/countdown.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/toast_bar.dart';
import '../data/seller_controller.dart';
import 'topup_sheet.dart';
import 'widgets/seller_widgets.dart';

const deliveryOptions = ['اليوم', 'يومين', '3 أيام', 'أسبوع'];

/// 20 · submit an offer (camera photo, locked price, delivery time, note).
/// 20b when already offered; 19b states as inline cards.
class SubmitOfferScreen extends ConsumerStatefulWidget {
  const SubmitOfferScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<SubmitOfferScreen> createState() => _SubmitState();
}

class _SubmitState extends ConsumerState<SubmitOfferScreen> {
  static const _photoH = 330.0;
  final _price = TextEditingController();
  final _note = TextEditingController();
  String _delivery = deliveryOptions[1];
  DateTime? _shotAt;
  OfferError? _error;
  bool _sent = false;

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _priceValue =>
      int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));

  void _send() {
    final ctl = ref.read(sellerProvider.notifier);
    final r = ctl.request(widget.requestId)!;
    final err = _shotAt == null
        ? OfferError.noPhoto
        : (_priceValue == null || _priceValue! <= 0)
        ? OfferError.priceAboveMax
        : ctl.submit(r.id, _priceValue!, _note.text);
    if (err == OfferError.noBalance) {
      TopupSheet.show(context);
      return;
    }
    setState(() {
      _error = err;
      _sent = err == null;
    });
  }

  void _onErrorAction() {
    switch (_error) {
      case OfferError.noPhoto:
        setState(() {
          _shotAt = DateTime.now();
          _error = null;
        });
      case OfferError.closed ||
          OfferError.alreadyOffered ||
          OfferError.earlySlotsFull:
        if (_error == OfferError.earlySlotsFull) {
          showAppToast(context, 'نبهك أول ما ينفتح الطلب للكل');
        }
        context.go(Routes.sellerInbox);
      case OfferError.noBalance:
        TopupSheet.show(context);
      default:
        setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sellerProvider);
    final ctl = ref.read(sellerProvider.notifier);
    final r = ctl.request(widget.requestId);
    if (r == null) return const SizedBox.shrink();
    final c = s.config;
    final blocked = _sent ? null : ctl.validate(r);
    final gate = switch (blocked) {
      OfferError.closed ||
      OfferError.alreadyOffered ||
      OfferError.earlySlotsFull => blocked,
      _ => null,
    };
    final already = _sent || r.offeredByMe;
    final shot = _shotAt ?? (already ? DateTime.now() : null);
    final feeNote = s.freeLeft
        ? 'السعر ما يتغير بعد الإرسال · باقيلك ${c.freeSelections - s.freeUsed} اختيارات مجانية'
        : 'السعر ما يتغير بعد الإرسال · خلصت المجانية · الاختيار يكلف ${iqd(c.selectionFee)}';
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              _CameraArea(
                image: r.image,
                height: _photoH,
                shotAt: shot,
                shop: s.shopName,
                onShoot: () => setState(() => _shotAt = DateTime.now()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'الطلب: ${r.title} · ${r.governorate} · ${r.offers}/${c.maxOffers} عروض',
                      style: AppText.muted,
                    ),
                    if (r.earlyUntil != null)
                      Countdown(
                        until: r.earlyUntil!,
                        builder: (_, left) =>
                            left == Duration.zero || gate != null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: OfferEarlyCard(left: left),
                              ),
                      ),
                    if (gate != null && !already) ...[
                      const SizedBox(height: AppSpacing.md),
                      OfferErrorCard(
                        error: gate,
                        request: r,
                        onAction: () {
                          _error = gate;
                          _onErrorAction();
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    LabeledField(
                      label: 'السعر النهائي مع التوصيل',
                      controller: _price,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _error = null),
                      style: AppText.number.copyWith(fontSize: 22),
                      trailing: Text(
                        'د.ع · حد الزبون ${thousands(r.maxPrice)}',
                        style: AppText.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const FieldLabel('مدة التوصيل'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final d in deliveryOptions)
                          AppChip(
                            d,
                            selected: d == _delivery,
                            onTap: () => setState(() => _delivery = d),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LabeledField(
                      label: 'ملاحظة',
                      controller: _note,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TintedNote(
                      feeNote,
                      bg: AppColors.warnBg,
                      fg: AppColors.warnText,
                      icon: AppIcon.lock,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      OfferErrorCard(
                        error: _error!,
                        request: r,
                        onAction: _onErrorAction,
                      ),
                    ],
                    const SizedBox(height: 14),
                    already
                        ? const AppButton(
                            'دزيت عرضك',
                            icon: AppIcon.check,
                            variant: AppButtonVariant.disabled,
                          )
                        : AppButton(
                            'دز العرض',
                            variant: gate == null
                                ? AppButtonVariant.primary
                                : AppButtonVariant.disabled,
                            onPressed: gate == null ? _send : null,
                          ),
                  ],
                ),
              ),
            ],
          ),
          if (already)
            const Positioned(
              left: 16,
              right: 16,
              top: _photoH - 30,
              child: ToastBar(
                'دزيت عرض على هالطلب قبل. عرض واحد بس لكل صفحة، وسعره ما يتغير',
                icon: AppIcon.check,
                iconColor: AppColors.gold,
              ),
            ),
        ],
      ),
    );
  }
}

/// 19b «وصلك الطلب قبل غيرك بدقيقتين».
class OfferEarlyCard extends StatelessWidget {
  const OfferEarlyCard({super.key, required this.left});
  final Duration left;

  @override
  Widget build(BuildContext context) => TintedNote(
    'عندك ${mmss(left)} قبل ما يوصل لباقي الصفحات.',
    title: 'وصلك الطلب قبل غيرك بدقيقتين',
    bg: AppColors.warnBg,
    fg: AppColors.warn,
    icon: AppIcon.zap,
  );
}

/// Camera-only capture area with the server watermark preview (page + time).
class _CameraArea extends StatelessWidget {
  const _CameraArea({
    required this.image,
    required this.height,
    required this.shotAt,
    required this.shop,
    required this.onShoot,
  });
  final String image;
  final double height;
  final DateTime? shotAt;
  final String shop;
  final VoidCallback onShoot;

  String get _time {
    final t = shotAt!;
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (shotAt != null)
          Image.asset(image, fit: BoxFit.cover)
        else
          const ColoredBox(color: AppColors.navy),
        Container(
          margin: const EdgeInsets.fromLTRB(30, 60, 30, 50),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.white.withValues(alpha: .5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        if (shotAt == null)
          Center(
            child: GestureDetector(
              onTap: onShoot,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(color: AppColors.gold, width: 5),
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(
                  AppIcon.camera,
                  color: AppColors.navy,
                  size: 30,
                ),
              ),
            ),
          ),
        Positioned(
          top: 50,
          right: 16,
          child: GestureDetector(
            onTap: () => popOr(context, Routes.sellerInbox),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(AppRadius.iconBox),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(
                AppIcon.back,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          right: 14,
          child: Pill(
            'كاميرا بس · بدون معرض',
            bg: AppColors.white,
            fg: AppColors.navy,
            icon: AppIcon.camera,
          ),
        ),
        if (shotAt != null)
          Positioned(
            bottom: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$shop · $_time',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 11, color: AppColors.white),
              ),
            ),
          ),
      ],
    ),
  );
}
