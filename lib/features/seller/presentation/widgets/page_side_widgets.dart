import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/notes.dart';

const requestReportReasons = [
  'غرض ممنوع',
  'بالطلب رقم أو حساب',
  'كلام مسيء',
  'طلب وهمي أو مكرر',
];

/// Live lists on the page side refresh this often while on screen.
const pagePollEvery = Duration(seconds: 12);

/// Calls [poll] every [pagePollEvery] while the screen is the top route and
/// the app is in the foreground.
mixin PagePolling<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;

  Future<void> poll();

  void startPolling() {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(pagePollEvery, (_) {
      if (!mounted || !_foreground) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      poll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final was = _foreground;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && !was && mounted) poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Lays cards in 1 column on phones, 2 on tablets and 3 on wide web.
class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({super.key, required this.children});
  final List<Widget> children;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      14,
      AppSpacing.screen,
      0,
    ),
    child: LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                children[i],
              ],
            ],
          );
        }
        final w = (c.maxWidth - _gap * (cols - 1)) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: 14,
          children: [for (final x in children) SizedBox(width: w, child: x)],
        );
      },
    ),
  );
}

/// One scrolling row of chips under the header.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      14,
      AppSpacing.screen,
      2,
    ),
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    ),
  );
}

/// «فلترة» chip with the count of active filters.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSvgIcon(AppIcon.filter, color: AppColors.white, size: 15),
          const SizedBox(width: 5),
          const Text(
            'فلترة',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// A chip that keeps the design look ([AppChip]).
Widget choiceChip(
  String label,
  bool on,
  VoidCallback onTap, {
  String? categoryKey,
}) => AppChip(label, selected: on, onTap: onTap, categoryKey: categoryKey);

/// Error card with «جرّب مرة ثانية».
class RetryCard extends StatelessWidget {
  const RetryCard({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyStateCard(
    icon: (error is ApiException && (error as ApiException).offline)
        ? AppIcon.wifiOff
        : AppIcon.alert,
    title: (error is ApiException && (error as ApiException).offline)
        ? 'ماكو إنترنت'
        : 'صار خلل',
    body: 'ما كدرنا نجيب البيانات. جرّب مرة ثانية.',
    action: AppButton(
      'جرّب مرة ثانية',
      compact: true,
      icon: AppIcon.refresh,
      variant: AppButtonVariant.ghost,
      onPressed: onRetry,
    ),
  );
}

/// Warning card with one action (unverified / suspended / receiving off).
class StateCardLink extends StatelessWidget {
  const StateCardLink({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: AppColors.warnBg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.strong.copyWith(color: AppColors.warn)),
        Text(body, style: AppText.muted.copyWith(color: AppColors.warnText)),
        const SizedBox(height: 10),
        AppButton(action, compact: true, onPressed: onTap),
      ],
    ),
  );
}

/// Grey skeleton rows while a list loads for the first time.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) => ResponsiveCards(
    children: [
      for (var i = 0; i < rows; i++)
        Container(
          height: 104,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [BoxShadow(color: AppColors.cardRing, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.cardRing,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: .7,
                      child: Container(height: 12, color: AppColors.cardRing),
                    ),
                    const SizedBox(height: 10),
                    FractionallySizedBox(
                      widthFactor: .45,
                      child: Container(height: 10, color: AppColors.cardRing),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
