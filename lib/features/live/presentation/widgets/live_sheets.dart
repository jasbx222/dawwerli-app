import 'package:flutter/material.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/ishtar_pattern.dart';
import '../../domain/live_request.dart';

/// `.sheet`: white, 28px top radius, pad 14/20/34, grab 44×5 (#DDD6C6, mb 16).
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x40000000),
          offset: Offset(0, -20),
          blurRadius: 50,
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6C6),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

TextStyle get _sheetTitle => TextStyle(
  fontSize: 18,
  height: AppText.lh(18),
  fontWeight: FontWeight.w700,
  color: AppColors.ink,
);

/// 10b
class CancelSheet extends StatelessWidget {
  const CancelSheet({
    super.key,
    required this.onConfirm,
    required this.onDismiss,
  });
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => AppSheet(
    children: [
      Text(AppStrings.cancelTitle, style: _sheetTitle),
      const SizedBox(height: 6),
      Text(AppStrings.cancelBody, style: AppText.muted),
      const SizedBox(height: 16),
      AppButton(
        AppStrings.cancelYes,
        variant: AppButtonVariant.danger,
        onPressed: onConfirm,
      ),
      const SizedBox(height: 10),
      AppButton(
        AppStrings.cancelNo,
        variant: AppButtonVariant.ghost,
        onPressed: onDismiss,
      ),
    ],
  );
}

/// 10c
class WidenedSheet extends StatelessWidget {
  const WidenedSheet({
    super.key,
    required this.request,
    required this.onRaise,
    required this.onKeep,
  });
  final LiveRequest request;
  final VoidCallback onRaise;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final govs = request.widenedTo;
    final joined = govs.length < 2
        ? govs.join()
        : '${govs.sublist(0, govs.length - 1).join(' و')} و${govs.last}';
    return AppSheet(
      children: [
        Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: IshtarBackground(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blue, AppColors.navy],
              ),
              child: const Center(
                child: AppSvgIcon(
                  AppIcon.pin,
                  size: 30,
                  color: AppColors.goldSoft,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        EmojiText(
          AppStrings.widenedTitle,
          textAlign: TextAlign.center,
          style: _sheetTitle,
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.widenedBody(request.waitedMinutes, joined),
          textAlign: TextAlign.center,
          style: AppText.muted,
        ),
        if (request.suggestedPrice != null) ...[
          const SizedBox(height: 14),
          AppCard(
            flat: true,
            color: AppColors.warnBg,
            padding: 12,
            child: EmojiText(
              AppStrings.raiseTip(thousands(request.suggestedPrice!)),
              style: AppText.muted.copyWith(color: AppColors.warnText),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(AppStrings.raisePrice, onPressed: onRaise),
        ],
        const SizedBox(height: 10),
        AppButton(
          AppStrings.keepAsIs,
          variant: AppButtonVariant.ghost,
          onPressed: onKeep,
        ),
      ],
    );
  }
}
