import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/order_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/exact_line.dart';
import '../../../core/widgets/order_redirect.dart';
import '../data/orders_providers.dart';
import '../domain/order.dart';
import 'order_widgets.dart';

/// 15 · Order timeline + «وصلك؟» delivery answer.
class OrderStatusScreen extends ConsumerWidget {
  const OrderStatusScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(orderProvider(orderId)).value;
    if (o == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    if (o.storeOrderId != null) {
      return OrderRedirect(Routes.storeOrder(o.storeOrderId!));
    }
    Future<void> answer(DeliveryAnswer a) async {
      await ref.read(ordersRepositoryProvider).answer(orderId, a);
      ref.invalidate(orderProvider(orderId));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: OrderStrings.statusTitle,
              subtitle: Text(OrderStrings.statusSub(o.orderNo, o.pageName)),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: AppCard(
                child: Column(
                  children: [for (final s in o.steps) _Step(step: s)],
                ),
              ),
            ),
            if (o.answer == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExactLine(
                        fontSize: 17,
                        child: Text.rich(
                          TextSpan(
                            text: '${OrderStrings.arrivedQ} ',
                            children: [
                              svgSpan(OrderIcon.box.of(AppColors.gold, 16)),
                            ],
                          ),
                          style: AppText.strong.copyWith(
                            fontSize: 17,
                            height: AppText.lh(17),
                          ),
                        ),
                      ),
                      ExactLine(
                        fontSize: 12.5,
                        child: Text(OrderStrings.inspect, style: AppText.muted),
                      ),
                      const SizedBox(height: 14),
                      LabelIconButton(
                        label: OrderStrings.yesReceived,
                        icon: AppIcon.check,
                        bg: AppColors.gold,
                        fg: AppColors.navy,
                        shadow: true,
                        onPressed: () => answer(DeliveryAnswer.received),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SmallGhostButton(
                              OrderStrings.notArrived,
                              onPressed: () =>
                                  answer(DeliveryAnswer.notReceived),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SmallGhostButton(
                              OrderStrings.mismatch,
                              onPressed: () => answer(DeliveryAnswer.mismatch),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: o.answer == DeliveryAnswer.received
                        ? [
                            _title(OrderStrings.receivedTitle),
                            ExactLine(
                              fontSize: 12.5,
                              child: Text(
                                OrderStrings.rateTitle(o.pageName),
                                style: AppText.muted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LabelIconButton(
                              label: OrderStrings.rateNow,
                              bg: AppColors.gold,
                              fg: AppColors.navy,
                              shadow: true,
                              onPressed: () =>
                                  context.push(Routes.rateOrder(orderId)),
                            ),
                          ]
                        : [
                            _title(OrderStrings.reportedTitle),
                            ExactLine(
                              fontSize: 12.5,
                              child: Text(
                                OrderStrings.reportedBody,
                                style: AppText.muted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AppButton(
                              OrderStrings.viewReport,
                              variant: AppButtonVariant.ghost,
                              onPressed: () =>
                                  context.push(Routes.disputeStatus),
                            ),
                          ],
                  ),
                ),
              ),
            if (o.answer == null) ...[
              const SizedBox(height: 12),
              Text(
                OrderStrings.askAgain,
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _title(String t) => ExactLine(
  fontSize: 17,
  child: Text(
    t,
    style: AppText.strong.copyWith(fontSize: 17, height: AppText.lh(17)),
  ),
);

class _Step extends StatelessWidget {
  const _Step({required this.step});
  final OrderStep step;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.done ? AppColors.blue : AppColors.surface,
            boxShadow: const [
              BoxShadow(color: AppColors.blue, spreadRadius: 2),
            ],
          ),
          alignment: Alignment.center,
          child: step.done
              ? const AppSvgIcon(
                  AppIcon.verified,
                  size: 14,
                  color: AppColors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExactLine(
                fontSize: 14,
                child: Text(step.title, style: AppText.strong),
              ),
              if (step.detail.isNotEmpty)
                ExactLine(
                  fontSize: 12.5,
                  child: Text(step.detail, style: AppText.muted),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
