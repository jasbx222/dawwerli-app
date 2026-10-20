import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/order_strings.dart';
import '../../../core/l10n/report_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/ishtar_pattern.dart';
import '../../live/presentation/widgets/live_sheets.dart';
import '../../offers/presentation/widgets/offer_widgets.dart';
import '../../orders/data/orders_providers.dart';

/// 27 · report a problem with an order; the block toggle asks via 27c.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    required this.orderId,
    this.initialReason = 1,
    this.openBlock = false,
  });
  final String orderId;
  final int initialReason;
  final bool openBlock;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late int reason = widget.initialReason;
  bool block = false;
  late bool sheet = widget.openBlock;

  @override
  Widget build(BuildContext context) {
    final o = ref.watch(orderProvider(widget.orderId)).value;
    if (o == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: ReportStrings.title,
                  subtitle: Text(OrderStrings.statusSub(o.orderNo, o.pageName)),
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(ReportStrings.what, style: AppText.label),
                      const SizedBox(height: 8),
                      for (var i = 0; i < ReportStrings.reasons.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ReportRadio(
                            label: ReportStrings.reasons[i],
                            on: i == reason,
                            onTap: () => setState(() => reason = i),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(ReportStrings.addPhoto, style: AppText.label),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/mock/cat_shoes_2.webp',
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const DashedCard(
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        flat: true,
                        color: AppColors.blueTint,
                        child: Text(
                          ReportStrings.evidence,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.502222,
                            color: AppColors.infoText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => block
                            ? setState(() => block = false)
                            : setState(() => sheet = true),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            const AppSvgIcon(
                              AppIcon.lock,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              ReportStrings.blockToggle,
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const Spacer(),
                            _Toggle(on: block),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        ReportStrings.send,
                        onPressed: () => context.pushReplacement(
                          Routes.reportSent(widget.orderId),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (sheet) ...[
            GestureDetector(
              onTap: () => setState(() => sheet = false),
              child: const ColoredBox(color: Color(0x8C070E1F)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BlockSheet(
                page: o.pageName,
                onConfirm: () => setState(() {
                  block = true;
                  sheet = false;
                }),
                onDismiss: () => setState(() => sheet = false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 27c · confirm blocking a page.
class BlockSheet extends StatelessWidget {
  const BlockSheet({
    super.key,
    required this.page,
    required this.onConfirm,
    required this.onDismiss,
  });
  final String page;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => AppSheet(
    children: [
      Text(
        ReportStrings.blockTitle(page),
        style: TextStyle(
          fontSize: 18,
          height: AppText.lh(18),
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 6),
      Text(ReportStrings.blockBody, style: AppText.muted),
      const SizedBox(height: 16),
      AppButton(
        ReportStrings.blockYes,
        icon: AppIcon.lock,
        variant: AppButtonVariant.danger,
        onPressed: onConfirm,
      ),
      const SizedBox(height: 10),
      AppButton(
        ReportStrings.blockNo,
        variant: AppButtonVariant.ghost,
        onPressed: onDismiss,
      ),
    ],
  );
}

/// `.inp` row with a radio on the far side; selected = `.inp.f`.
class ReportRadio extends StatelessWidget {
  const ReportRadio({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on ? AppColors.blue : AppColors.border,
          width: 1.5,
        ),
        boxShadow: on
            ? const [BoxShadow(color: Color(0x1F1F4E9C), spreadRadius: 4)]
            : null,
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15, height: 1.5)),
          const Spacer(),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue, width: on ? 6 : 2),
            ),
          ),
        ],
      ),
    ),
  );
}

/// `.tog` (44×26); off = `.tog.x`.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 26,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: on ? AppColors.blue : AppColors.dotOff,
      borderRadius: BorderRadius.circular(99),
    ),
    // RTL: on = knob left (CSS left:3px), off = right.
    alignment: on
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// 27b · complaint received.
class ReportSentScreen extends ConsumerWidget {
  const ReportSentScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(orderProvider(orderId)).value;
    void close() => context.canPop() ? context.pop() : context.go(Routes.home);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: ReportStrings.sentTitle,
            subtitle: Text('#${o?.orderNo ?? ''}'),
            onBack: close,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: IshtarBackground(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.blue, AppColors.navy],
                    ),
                    child: const Center(
                      child: AppSvgIcon(
                        AppIcon.flag,
                        size: 52,
                        color: AppColors.goldSoft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(ReportStrings.trackLabel, style: AppText.big),
                Text(
                  // Mock tracking number until the complaints API lands.
                  'CMP-30917',
                  textDirection: TextDirection.ltr,
                  style: AppText.big.copyWith(color: AppColors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  ReportStrings.sentBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.7,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
            child: AppButton(ReportStrings.done, onPressed: close),
          ),
        ],
      ),
    );
  }
}
