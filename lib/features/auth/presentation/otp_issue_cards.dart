import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/state_card.dart';

String mmss(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class OtpExpiredCard extends StatelessWidget {
  const OtpExpiredCard({super.key, this.onResend});
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) => StateCard(
        icon: AppIcon.clock,
        tint: AppColors.warnBg,
        tone: AppColors.warn,
        title: AppStrings.stExpiredTitle,
        body: const TextSpan(text: AppStrings.stExpiredBody),
        action: AppStrings.otpResend,
        onAction: onResend,
      );
}

class OtpWhatsappCard extends StatelessWidget {
  const OtpWhatsappCard({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => StateCard(
        icon: AppIcon.whatsapp,
        tint: AppColors.successBg,
        tone: AppColors.success,
        title: AppStrings.stWhatsTitle,
        body: const TextSpan(text: AppStrings.stWhatsBody),
        action: AppStrings.stWhatsAction,
        actionVariant: AppButtonVariant.whatsapp,
        onAction: onOpen,
      );
}

class OtpWrongCard extends StatelessWidget {
  const OtpWrongCard({super.key, required this.attemptsLeft, this.onClear});
  final int attemptsLeft;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => StateCard(
        icon: AppIcon.xCircle,
        tint: AppColors.dangerBg,
        tone: AppColors.danger,
        title: AppStrings.stWrongTitle,
        body: TextSpan(children: [
          const TextSpan(text: AppStrings.stWrongBodyPre),
          TextSpan(text: AppStrings.attemptsLeft(attemptsLeft), style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(text: AppStrings.stWrongBodyPost),
        ]),
        action: AppStrings.stWrongAction,
        actionVariant: AppButtonVariant.ghost,
        onAction: onClear,
      );
}

/// 15-minute lock after 5 wrong codes.
class OtpLockedCard extends StatelessWidget {
  const OtpLockedCard({super.key, required this.retryIn, this.onChangeNumber});
  final Duration retryIn;
  final VoidCallback? onChangeNumber;

  @override
  Widget build(BuildContext context) => StateCard(
        icon: AppIcon.lockDot,
        tint: AppColors.dangerBg,
        tone: AppColors.danger,
        title: AppStrings.stLockedTitle,
        body: TextSpan(children: [
          const TextSpan(text: AppStrings.stLockedBodyPre),
          TextSpan(text: mmss(retryIn), style: AppText.number.copyWith(fontWeight: FontWeight.w700)),
          const TextSpan(text: AppStrings.stLockedBodyPost),
        ]),
        action: AppStrings.stLockedAction,
        actionVariant: AppButtonVariant.ghost,
        onAction: onChangeNumber,
      );
}

class OtpRateLimitedCard extends StatelessWidget {
  const OtpRateLimitedCard({super.key, required this.retryIn});
  final Duration retryIn;

  @override
  Widget build(BuildContext context) => StateCard(
        icon: AppIcon.hourglass,
        tint: AppColors.blueTint,
        tone: AppColors.blue,
        title: AppStrings.stRateTitle,
        body: const TextSpan(text: AppStrings.stRateBody),
        action: '${AppStrings.otpResendIn}${mmss(retryIn)}',
        actionVariant: AppButtonVariant.disabled,
      );
}
