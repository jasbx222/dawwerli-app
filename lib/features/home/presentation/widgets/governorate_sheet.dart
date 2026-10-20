import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/home_providers.dart';

/// Governorate picker for the home header. No dedicated design exists, so it uses the
/// shared `.sheet` + `.dim` styles (white, 28px top radius, pad 14/20/34, 44×5 grab,
/// overlay rgba(7,14,31,.55)) and the governorate chips from 05.
Future<void> showGovernorateSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: const Color(0x8C070E1F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _GovernorateSheet(),
  );
}

class _GovernorateSheet extends ConsumerWidget {
  const _GovernorateSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final govs = ref.watch(governoratesProvider).value ?? const <String>[];
    final current = ref.watch(homeGovernorateProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
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
          Text(
            AppStrings.pickGovernorate,
            style: AppText.strong.copyWith(
              fontSize: 16,
              height: AppText.lh(16),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in govs)
                AppChip(
                  g,
                  selected: g == current,
                  onTap: () {
                    ref.read(selectedGovernorateProvider.notifier).set(g);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
