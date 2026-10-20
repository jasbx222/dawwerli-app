import 'package:flutter/material.dart';

import '../../../core/widgets/app_image.dart';

import '../../../core/widgets/app_toggle.dart';
import '../../../core/widgets/radio_row.dart';

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
import '../../../core/api/api_client.dart';
import '../../../core/api/media.dart';
import '../../../core/api/picker.dart';
import '../../more/more_data.dart';
import '../../orders/data/orders_providers.dart';
import '../../orders/domain/order.dart';

/// 27 · report a problem with an order; the block toggle asks via 27c.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    required this.orderId,
    this.initialReason = 1,

  });
  final String orderId;
  final int initialReason;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  /// Server reason codes, aligned with [ReportStrings.reasons].
  static const _reasonCodes = [
    'notDelivered',
    'mismatch',
    'priceChanged',
    'depositRequest',
    'contactSolicitation',
    'abuse',
    'bannedItem',
  ];
  static const _trackPrefix = 'CMP-';
  static const _trackLength = 8;

  late int reason = widget.initialReason;
  bool block = false;
  bool sheet = false;
  bool _busy = false;
  String? _photo;

  Future<void> _send(OrderStatus o) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final key = await uploadImage(api, _photo, 'disputes');
      final res = await api.post<Map<String, dynamic>>(
        '/api/v1/orders/${o.id}/complaint',
        {
          'target': 'page',
          'targetId': o.pageId,
          'reason': _reasonCodes[reason],
          'photoKey': key,
        },
      );
      if (block) {
        await ref.read(blockedProvider.notifier).block(o.pageId, name: o.pageName);
      }
      final no = _trackPrefix +
          res.s('id').replaceAll('-', '').substring(0, _trackLength).toUpperCase();
      if (mounted) context.pushReplacement(Routes.reportSent(widget.orderId, no));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                          child: RadioRow(
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
                          if (_photo case final p?) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AppImage(
                                p,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          GestureDetector(
                            onTap: () async {
                              final p = await pickPhoto(camera: false);
                              if (p != null && mounted) setState(() => _photo = p);
                            },
                            child: const DashedCard(
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
                            AppToggle(on: block),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        ReportStrings.send,
                        onPressed: () => _send(o),
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

/// 27b · complaint received.
class ReportSentScreen extends ConsumerWidget {
  /// Complaint tracking number shown to the customer.
  final String trackNo;

  const ReportSentScreen({
    super.key,
    required this.orderId,
    required this.trackNo,
  });
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
                  trackNo,
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
