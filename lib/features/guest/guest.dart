import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/emoji_text.dart';
import '../live/presentation/widgets/live_sheets.dart';

/// 51 · browsing without an account («تصفح بدون حساب» on 02).
class GuestMode extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final guestProvider = NotifierProvider<GuestMode, bool>(GuestMode.new);

/// 51 · replaces the live-request card for guests.
class GuestCard extends StatelessWidget {
  const GuestCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x660B1A3F),
          offset: Offset(0, 20),
          blurRadius: 40,
          spreadRadius: -20,
        ),
      ],
    ),
    child: Column(
      children: [
        EmojiText(
          AppStrings.guestTitle,
          textAlign: TextAlign.center,
          style: AppText.strong.copyWith(fontSize: 17, height: AppText.lh(17)),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.guestSub,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.grey),
        ),
      ],
    ),
  );
}

/// 51 · guests trying to post (or open a personal tab) are asked to sign in.
Future<void> showGuestSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x8C070E1F),
  isScrollControlled: true,
  builder: (c) => AppSheet(
    children: [
      EmojiText(
        AppStrings.guestSheetTitle,
        style: AppText.strong.copyWith(fontSize: 19, height: AppText.lh(19)),
      ),
      const SizedBox(height: 6),
      Text(
        AppStrings.guestSheetBody,
        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.grey),
      ),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () {
          Navigator.of(c).pop();
          context.push(Routes.login);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.blue, width: 1.5),
          ),
          child: Text(
            '+964  770 123 4567',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      AppButton(
        AppStrings.guestSend,
        onPressed: () {
          Navigator.of(c).pop();
          context.push(Routes.login);
        },
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => Navigator.of(c).pop(),
        child: Text(
          AppStrings.guestKeepBrowsing,
          textAlign: TextAlign.center,
          style: AppText.strong.copyWith(color: AppColors.blue),
        ),
      ),
    ],
  ),
);

/// Runs [action] for members; guests get the sign-in sheet instead.
void memberOnly(BuildContext context, WidgetRef ref, VoidCallback action) =>
    ref.read(guestProvider) ? showGuestSheet(context) : action();
