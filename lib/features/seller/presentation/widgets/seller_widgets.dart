import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/notes.dart';
import '../../../../core/widgets/pill.dart';
import '../../../../core/widgets/radio_row.dart';
import '../../../../core/widgets/state_card.dart';
import '../../data/seller_controller.dart';
import '../../domain/seller_models.dart';

String iqd(int v) => '${thousands(v)} د.ع';

/// "1:12" — minutes:seconds left.
String mmss(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Card with a thumb, title + muted line, optional [trailing] pill and [footer].
class ThumbCard extends StatelessWidget {
  const ThumbCard({
    super.key,
    required this.image,
    required this.title,
    required this.sub,
    this.trailing,
    this.footer,
    this.onTap,
  });
  final String image;
  final String title;
  final String sub;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PhotoThumb(image),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.strong.copyWith(fontSize: 14.5)),
                    Text(sub, style: AppText.muted),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          ?footer,
        ],
      ),
    ),
  );
}

/// Small in-row button (`.btn` padding 10/16, 14px).
class SmallButton extends StatelessWidget {
  const SmallButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppIcon? icon;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
    child: AppButton(
      label,
      compact: true,
      icon: icon,
      variant: variant,
      onPressed: onPressed,
    ),
  );
}

/// 19b / 22b state card for an [OfferError].
class OfferErrorCard extends StatelessWidget {
  const OfferErrorCard({
    super.key,
    required this.error,
    required this.request,
    this.onAction,
  });
  final OfferError error;
  final SellerRequest? request;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, tone, title, body, action, ghost) = switch (error) {
      OfferError.earlySlotsFull => (
        AppIcon.lock,
        PillTone.blue.bg,
        AppColors.blue,
        'المكانين المدفوعين انملوا',
        'صفحتين مشتركة قدّموا. استنى دقيقتين وينفتح الطلب للكل، حتى يبقى 3 أماكن للصفحات العادية.',
        'نبهني من ينفتح',
        true,
      ),
      OfferError.closed => (
        AppIcon.lock,
        PillTone.stone.bg,
        PillTone.stone.fg,
        'الطلب انقفل',
        'وصلته 5 عروض، أو الزبون ألغاه.',
        'رجوع للطلبات',
        true,
      ),
      OfferError.alreadyOffered => (
        AppIcon.check,
        PillTone.stone.bg,
        PillTone.stone.fg,
        'دزيت عرضك',
        'دزيت عرض على هالطلب قبل. عرض واحد بس لكل صفحة، وسعره ما يتغير',
        'رجوع للطلبات',
        true,
      ),
      OfferError.priceAboveMax => (
        AppIcon.alert,
        AppColors.dangerBg,
        AppColors.danger,
        'السعر أعلى من حد الزبون',
        'حد الزبون ${iqd(request?.maxPrice ?? 0)}. نزّل السعر حتى ينرسل.',
        'عدّل السعر',
        false,
      ),
      OfferError.contactInNote => (
        AppIcon.link,
        AppColors.dangerBg,
        AppColors.danger,
        'شيل الرقم أو الرابط من الملاحظة',
        'العرض ما ينرسل إذا بيه تلفون أو رابط أو @حساب.',
        'عدّل الملاحظة',
        true,
      ),
      OfferError.noPhoto => (
        AppIcon.camera,
        AppColors.dangerBg,
        AppColors.danger,
        'صورة من المعرض ما تنقبل',
        'لازم تصوّر الغرض هسه بكاميرا التطبيق.',
        'افتح الكاميرا',
        false,
      ),
      OfferError.noBalance => (
        AppIcon.cash,
        AppColors.warnBg,
        AppColors.warn,
        'رصيدك ما يكفي',
        'خلصت الاختيارات المجانية. عبّي رصيدك حتى تدز العرض.',
        'عبّي هسه',
        false,
      ),
    };
    return StateCard(
      icon: icon,
      tint: tint,
      tone: tone,
      title: title,
      body: TextSpan(text: body),
      action: action,
      actionVariant: ghost ? AppButtonVariant.ghost : AppButtonVariant.primary,
      onAction: onAction,
    );
  }
}

/// Bottom sheet with a title, sub line, radio reasons and send/cancel (21d, request report).
class ReasonSheet extends StatefulWidget {
  const ReasonSheet({
    super.key,
    required this.title,
    required this.sub,
    required this.reasons,
    required this.onSend,
    this.warning,
  });
  final String title;
  final String sub;
  final List<String> reasons;
  final String? warning;
  final ValueChanged<int> onSend;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String sub,
    required List<String> reasons,
    required ValueChanged<int> onSend,
    String? warning,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C070E1F),
    builder: (_) => ReasonSheet(
      title: title,
      sub: sub,
      reasons: reasons,
      warning: warning,
      onSend: onSend,
    ),
  );

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  int _sel = 0;

  @override
  Widget build(BuildContext context) => AppSheet(
    children: [
      Text(widget.title, style: AppText.strong.copyWith(fontSize: 18)),
      const SizedBox(height: 4),
      Text(widget.sub, style: AppText.muted),
      const SizedBox(height: AppSpacing.md),
      for (final (i, r) in widget.reasons.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: RadioRow(
            label: r,
            on: i == _sel,
            onTap: () => setState(() => _sel = i),
          ),
        ),
      if (widget.warning != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              AppSvgIcon(
                AppIcon.alert,
                color: AppColors.danger,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.warning!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        'دز البلاغ',
        onPressed: () {
          Navigator.pop(context);
          widget.onSend(_sel);
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        'إلغاء',
        variant: AppButtonVariant.ghost,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}
