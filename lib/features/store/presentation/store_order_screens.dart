import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/radio_row.dart';
import '../../more/more_data.dart';
import '../data/store_data.dart';
import 'widgets/product_card.dart';
import 'widgets/rating_sheet.dart';
import 'widgets/store_widgets.dart';

// ───────────────────────── shared bits ─────────────────────────

/// Arabic label of a store order status.
String storeStatusLabel(String status) => switch (status) {
  'new' => 'جديد',
  'accepted' => 'مقبول',
  'out_for_delivery' => 'بالتوصيل',
  'delivered' => 'مستلم',
  'cancelled' => 'ملغي',
  'rejected' => 'مرفوض',
  _ => status,
};

PillTone storeStatusTone(String status) => switch (status) {
  'new' => PillTone.blue,
  'accepted' || 'out_for_delivery' => PillTone.gold,
  'delivered' => PillTone.teal,
  'cancelled' || 'rejected' => PillTone.red,
  _ => PillTone.stone,
};

/// Colored status pill used on rows and the details header.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final t = storeStatusTone(status);
    return Pill(
      storeStatusLabel(status),
      bg: t.bg,
      fg: t.fg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.image, {this.size = 64, this.radius = 16});
  final String image;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Container(
      width: size,
      height: size,
      color: AppColors.blueTint,
      alignment: Alignment.center,
      child: image.isEmpty
          ? AppSvgIcon(
              AppIcon.bag,
              size: size * .4,
              color: AppColors.blue.withValues(alpha: .4),
            )
          : AppImage(image, width: size, height: size, fit: BoxFit.cover),
    ),
  );
}

/// White rounded section card with the store's subtle shadow.
class _Section extends StatelessWidget {
  const _Section({required this.child, this.title, this.padding = 16});
  final Widget child;
  final String? title;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(ProductCard.radius),
      boxShadow: ProductCard.shadow,
    ),
    child: title == null
        ? child
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title!, style: AppText.strong.copyWith(fontSize: 15)),
              const SizedBox(height: 12),
              child,
            ],
          ),
  );
}

Future<void> _cancel(BuildContext context, WidgetRef ref, StoreOrder o) async {
  final sure = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (c) => AppSheet(
      children: [
        Text(
          'تلغي الطلب ${o.no}؟',
          textAlign: TextAlign.center,
          style: AppText.big.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'تكدر تلغيه ما دام الصفحة بعدها ما قبلته. الكمية ترجع للصفحة.',
          textAlign: TextAlign.center,
          style: AppText.muted.copyWith(fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 18),
        AppButton(
          'إي، ألغي الطلب',
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.of(c).pop(true),
        ),
        const SizedBox(height: 10),
        AppButton(
          'لا، خليه',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(c).pop(false),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  try {
    await ref
        .read(apiClientProvider)
        .post<Map<String, dynamic>>('/api/v1/store/orders/${o.id}/cancel');
    if (context.mounted) showAppToast(context, 'انلغى الطلب');
  } catch (e) {
    if (context.mounted) {
      showAppToast(context, storeError(e), icon: AppIcon.alert);
    }
  }
  ref
    ..invalidate(storeOrderProvider(o.id))
    ..invalidate(storeOrdersProvider);
}

/// Adds every line of [o] back to the cart, then opens it.
Future<void> _reorder(BuildContext context, WidgetRef ref, StoreOrder o) async {
  var added = 0;
  for (final l in o.lines) {
    if (!context.mounted) return;
    if (await addToCart(context, ref, l.productId, quantity: l.quantity)) {
      added++;
    }
  }
  if (!context.mounted) return;
  if (added > 0) {
    context.push(Routes.cart);
  }
}

/// Rate: one line opens the sheet, several lines ask which product first.
Future<void> _rate(BuildContext context, WidgetRef ref, StoreOrder o) async {
  if (o.lines.length == 1) {
    final l = o.lines.first;
    await showRateSheet(
      context,
      ref,
      productId: l.productId,
      productName: l.name,
      pageId: o.pageId,
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) => AppSheet(
      children: [
        Text('قيّم مشترياتك', style: AppText.big.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        for (final l in o.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RateLine(line: l, pageId: o.pageId),
          ),
      ],
    ),
  );
}

// ───────────────────────── «طلباتي» ─────────────────────────

enum OrderFilter {
  all('الكل'),
  fresh('جديد'),
  accepted('مقبول'),
  shipping('بالتوصيل'),
  delivered('مستلم'),
  ended('ملغي/مرفوض');

  const OrderFilter(this.label);
  final String label;

  bool matches(StoreOrder o) => switch (this) {
    all => true,
    fresh => o.status == 'new',
    accepted => o.status == 'accepted',
    shipping => o.status == 'out_for_delivery',
    delivered => o.delivered,
    ended => o.ended,
  };
}

/// Horizontally scrolling status filter chips with counts.
class OrderFilterChips extends StatelessWidget {
  const OrderFilterChips({
    super.key,
    required this.orders,
    required this.value,
    required this.onChanged,
    this.side = 16,
  });
  final List<StoreOrder> orders;
  final OrderFilter value;
  final ValueChanged<OrderFilter> onChanged;
  final double side;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsetsDirectional.symmetric(horizontal: side),
    child: Row(
      children: [
        for (final f in OrderFilter.values) ...[
          if (f != OrderFilter.values.first) const SizedBox(width: 8),
          _Chip(
            label: f.label,
            count: orders.where(f.matches).length,
            on: f == value,
            onTap: () => onChanged(f),
          ),
        ],
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.on,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: '$label، $count',
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 8, 7),
        decoration: BoxDecoration(
          color: on ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? AppColors.navy : AppColors.cardRing),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 13,
                color: on ? AppColors.white : AppColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: on
                    ? AppColors.white.withValues(alpha: .18)
                    : AppColors.tabTrack,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppText.number.copyWith(
                  fontSize: 11.5,
                  color: on ? AppColors.white : AppColors.tabText,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One order in «طلباتي»: thumbnail, first product (+N), unit price, a muted
/// count · total line, the status pill and the actions that fit its status.
class OrderRowCard extends ConsumerWidget {
  const OrderRowCard({super.key, required this.order});
  final StoreOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = order;
    final first = o.lines.isEmpty ? null : o.lines.first;
    final more = o.lines.length - 1;
    final myStars = o.delivered && first != null
        ? ref.watch(myRatingProvider(first.productId)).value?.stars
        : null;
    final actions = <Widget>[
      if (o.active)
        _RowAction(
          'تابع الطلب',
          primary: true,
          onTap: () => context.push(Routes.storeOrder(o.id)),
        ),
      if (o.isNew)
        _RowAction(
          'إلغاء',
          danger: true,
          onTap: () => _cancel(context, ref, o),
        ),
      if (o.delivered) ...[
        _RowAction('اطلب مرة ثانية', onTap: () => _reorder(context, ref, o)),
        if (myStars == null)
          _RowAction(
            'قيّم',
            primary: true,
            onTap: () => _rate(context, ref, o),
          ),
      ],
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ProductCard.radius),
        boxShadow: ProductCard.shadow,
      ),
      child: Semantics(
        button: true,
        label: 'طلب ${o.no}، ${storeStatusLabel(o.status)}',
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(ProductCard.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(ProductCard.radius),
            onTap: () => context.push(Routes.storeOrder(o.id)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Thumb(first?.image ?? '', size: 72),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: first?.name ?? o.no,
                                      children: [
                                        if (more > 0)
                                          TextSpan(
                                            text: '  +$more',
                                            style: AppText.muted.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.strong.copyWith(
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OrderStatusPill(o.status),
                              ],
                            ),
                            if (first != null && first.price > 0)
                              Text(
                                storePrice(first.price),
                                style: AppText.number.copyWith(
                                  fontSize: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                text: '${o.count} قطعة · المجموع ',
                                children: [
                                  TextSpan(
                                    text: storePrice(o.subtotal),
                                    style: AppText.number.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.muted,
                            ),
                            if (myStars != null) ...[
                              const SizedBox(height: 4),
                              StarRow(value: myStars.toDouble(), size: 14),
                            ],
                            if (actions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (var i = 0; i < actions.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(child: actions[i]),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction(
    this.label, {
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger
        ? AppColors.danger
        : primary
        ? AppColors.navy
        : AppColors.ink;
    final bg = primary ? AppColors.gold : AppColors.tabTrack;
    return Semantics(
      button: true,
      child: Material(
        color: danger ? AppColors.dangerBg : bg,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(color: fg, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return _Section(
      padding: 12,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.tabTrack,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(140, 13),
                const SizedBox(height: 10),
                bar(70, 11),
                const SizedBox(height: 10),
                bar(110, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «طلباتي» · store orders with status filters.
class StoreOrdersScreen extends ConsumerStatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  ConsumerState<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends ConsumerState<StoreOrdersScreen> {
  var _filter = OrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(storeOrdersProvider);
    final side = StoreWidth.sideFor(MediaQuery.sizeOf(context).width);
    return AppPage(
      title: 'طلباتي',
      subtitle: 'طلبات المتجر',
      children: [
        ...orders.when(
          skipLoadingOnRefresh: true,
          loading: () => [
            for (var i = 0; i < 3; i++)
              const StoreWidth(maxWidth: 760, top: 12, child: _RowSkeleton()),
          ],
          error: (e, _) => [
            StoreWidth(
              maxWidth: 760,
              child: StoreMessage(
                icon: AppIcon.wifiOff,
                title: 'ما قدرنا نجيب طلباتك',
                body: 'تأكد من النت وجرّب مرة ثانية.',
                onRetry: () => ref.invalidate(storeOrdersProvider),
              ),
            ),
          ],
          data: (list) {
            final shown = list.where(_filter.matches).toList();
            return [
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 760 + side * 2),
                  child: OrderFilterChips(
                    orders: list,
                    value: _filter,
                    side: side,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),
              ),
              if (shown.isEmpty)
                StoreWidth(
                  maxWidth: 760,
                  child: StoreMessage(
                    icon: AppIcon.clipboardList,
                    title: list.isEmpty
                        ? 'ما عندك طلبات بعد'
                        : 'ماكو طلبات «${_filter.label}»',
                    body: list.isEmpty
                        ? 'تصفّح منتجات الصفحات واطلب اللي يعجبك، وتابعه من هنا.'
                        : 'جرّب فلتر ثاني.',
                  ),
                )
              else
                for (final o in shown)
                  StoreWidth(
                    maxWidth: 760,
                    top: 12,
                    child: OrderRowCard(order: o),
                  ),
            ];
          },
        ),
      ],
    );
  }
}

// ───────────────────────── order details ─────────────────────────

/// Order details: summary, status timeline, items, delivery, payment, totals,
/// the page card, and a sticky cancel / rate action.
class StoreOrderScreen extends ConsumerWidget {
  const StoreOrderScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(storeOrderProvider(id));
    return order.when(
      skipLoadingOnRefresh: true,
      loading: () => const AppPage(
        title: 'تفاصيل الطلب',
        children: [
          StoreWidth(maxWidth: 760, child: _RowSkeleton()),
          StoreWidth(maxWidth: 760, top: 12, child: _RowSkeleton()),
        ],
      ),
      error: (e, _) => AppPage(
        title: 'تفاصيل الطلب',
        children: [
          StoreWidth(
            maxWidth: 760,
            child: e is ApiException && e.status == 404
                ? const StoreMessage(
                    title: 'ما لكينا هالطلب',
                    body: 'يمكن الرابط غلط أو الطلب مو إلك.',
                  )
                : StoreMessage(
                    icon: AppIcon.wifiOff,
                    title: 'ما قدرنا نفتح الطلب',
                    body: 'تأكد من النت وجرّب مرة ثانية.',
                    onRetry: () => ref.invalidate(storeOrderProvider(id)),
                  ),
          ),
        ],
      ),
      data: (o) => _Details(order: o),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.order});
  final StoreOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = order;
    final page = o.pageId.isEmpty
        ? null
        : ref.watch(pageProfileProvider(o.pageId)).value;
    Widget gap(Widget child) =>
        StoreWidth(maxWidth: 760, top: 12, child: child);
    final bottom = o.isNew
        ? AppButton(
            'إلغاء الطلب',
            variant: AppButtonVariant.danger,
            onPressed: () => _cancel(context, ref, o),
          )
        : o.delivered
        ? AppButton(
            'قيّم المنتجات',
            icon: AppIcon.star,
            onPressed: () => _rate(context, ref, o),
          )
        : null;
    return AppPage(
      title: 'تفاصيل الطلب',
      trailing: _Menu(order: o),
      bottom: bottom == null
          ? null
          : StoreWidth(top: 0, padded: false, maxWidth: 760, child: bottom),
      children: [
        StoreWidth(
          maxWidth: 760,
          child: _Summary(order: o, image: page?.image),
        ),
        gap(
          _Section(
            title: 'حالة الطلب',
            child: _Timeline(order: o),
          ),
        ),
        gap(
          _Section(
            title: o.lines.length == 1
                ? 'المنتج'
                : 'المنتجات (${o.lines.length})',
            child: Column(
              children: [
                for (var i = 0; i < o.lines.length; i++) ...[
                  if (i > 0) Divider(height: 20, color: AppColors.divider),
                  _ItemLine(line: o.lines[i], pageId: o.pageId),
                ],
              ],
            ),
          ),
        ),
        gap(
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoRow(
                  icon: AppIcon.pin,
                  title: 'عنوان التوصيل',
                  body: o.address.isEmpty ? '—' : o.address,
                ),
                if ((o.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: AppIcon.message,
                    title: 'ملاحظة',
                    body: o.note!,
                  ),
                ],
                const SizedBox(height: 14),
                _InfoRow(
                  icon: AppIcon.cash,
                  title: 'طريقة الدفع',
                  body: o.payment == 'electronic'
                      ? 'دفع إلكتروني${o.paymentStatus == 'paid' ? ' · مدفوع' : ''}'
                      : 'كاش عند الاستلام',
                ),
              ],
            ),
          ),
        ),
        gap(
          _Section(
            title: 'الحساب',
            child: Column(
              children: [
                _MoneyRow('المجموع الفرعي', storePrice(o.subtotal)),
                const SizedBox(height: 8),
                Divider(height: 12, color: AppColors.divider),
                _MoneyRow('المجموع', storePrice(o.subtotal), strong: true),
              ],
            ),
          ),
        ),
        if (o.pageId.isNotEmpty)
          gap(
            _PageCard(
              name: page?.name ?? o.pageName,
              image: page?.image,
              rating: page?.rating,
              onOpen: () => context.push(Routes.pageProfile(o.pageId)),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu({required this.order});
  final StoreOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
    tooltip: 'خيارات الطلب',
    color: AppColors.surface,
    icon: Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 1.5),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
    onSelected: (v) => switch (v) {
      'cancel' => _cancel(context, ref, order),
      _ => _report(context, order),
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'report',
        child: Text('بلّغ عن مشكلة بالطلب', style: AppText.body),
      ),
      if (order.isNew)
        PopupMenuItem(
          value: 'cancel',
          child: Text(
            'إلغاء الطلب',
            style: AppText.body.copyWith(color: AppColors.danger),
          ),
        ),
    ],
  );

  Future<void> _report(BuildContext context, StoreOrder o) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderReportSheet(order: o),
    );
    if (sent == true && context.mounted) {
      showAppToast(context, 'وصلنا بلاغك، فريقنا يراجعه');
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.order, this.image});
  final StoreOrder order;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رقم الطلب', style: AppText.muted),
                    Semantics(
                      button: true,
                      label: 'انسخ رقم الطلب ${o.no}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: o.no));
                          if (context.mounted) {
                            showAppToast(
                              context,
                              'انسخ رقم الطلب',
                              icon: AppIcon.copy,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                o.no,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.number.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppSvgIcon(
                              AppIcon.copy,
                              size: 16,
                              color: AppColors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusPill(o.status),
            ],
          ),
          Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              _Avatar(name: o.pageName, image: image),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.pageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.strong,
                    ),
                    if (o.createdAt != null)
                      Text(
                        'انطلب ${dayTimeLabel(o.createdAt!)}',
                        style: AppText.muted,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.image, this.size = 40});
  final String name;
  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .35),
    child: (image ?? '').isNotEmpty
        ? AppImage(image!, width: size, height: size, fit: BoxFit.cover)
        : Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            color: AppColors.blueTint,
            child: Text(
              name.isEmpty ? '؟' : name.characters.first,
              style: AppText.strong.copyWith(
                color: AppColors.blue,
                fontSize: size * .42,
              ),
            ),
          ),
  );
}

/// Vertical steps جديد → مقبول → بالتوصيل → مستلم, each reached one with its
/// time. A rejected / cancelled order ends on a red terminal step.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final StoreOrder order;

  static const _flow = ['new', 'accepted', 'out_for_delivery', 'delivered'];

  @override
  Widget build(BuildContext context) {
    final o = order;
    final at = {for (final s in o.history) s.status: s.at};
    final steps =
        <
          ({String status, DateTime? at, bool reached, bool current, bool bad})
        >[];
    if (o.ended) {
      final reachedFlow = _flow.where(at.containsKey).toList();
      if (reachedFlow.isEmpty) reachedFlow.add('new');
      for (final s in reachedFlow) {
        steps.add((
          status: s,
          at: at[s],
          reached: true,
          current: false,
          bad: false,
        ));
      }
      steps.add((
        status: o.status,
        at: at[o.status] ?? o.statusChangedAt,
        reached: true,
        current: true,
        bad: true,
      ));
    } else {
      final idx = _flow.indexOf(o.status);
      for (var i = 0; i < _flow.length; i++) {
        steps.add((
          status: _flow[i],
          at: at[_flow[i]],
          reached: i <= idx,
          // A delivered order is complete: every step shows as done.
          current: i == idx && o.status != 'delivered',
          bad: false,
        ));
      }
    }
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _Step(
            label: storeStatusLabel(steps[i].status),
            hint: _hint(steps[i].status, o),
            at: steps[i].at,
            reached: steps[i].reached,
            current: steps[i].current,
            bad: steps[i].bad,
            last: i == steps.length - 1,
            nextReached: i + 1 < steps.length && steps[i + 1].reached,
          ),
      ],
    );
  }

  static String _hint(String status, StoreOrder o) => switch (status) {
    'new' => 'وصل طلبك للصفحة',
    'accepted' => 'الصفحة قبلت الطلب وتجهّزه',
    'out_for_delivery' => 'طلبك بالطريق إليك',
    'delivered' => 'وصلك الطلب',
    'cancelled' => (o.reason ?? '').isEmpty ? 'انلغى الطلب' : o.reason!,
    'rejected' => (o.reason ?? '').isEmpty ? 'الصفحة رفضت الطلب' : o.reason!,
    _ => '',
  };
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.hint,
    required this.at,
    required this.reached,
    required this.current,
    required this.bad,
    required this.last,
    required this.nextReached,
  });
  final String label;
  final String hint;
  final DateTime? at;
  final bool reached;
  final bool current;
  final bool bad;
  final bool last;
  final bool nextReached;

  @override
  Widget build(BuildContext context) {
    final accent = bad ? AppColors.danger : AppColors.gold;
    final dot = Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current
            ? accent.withValues(alpha: .18)
            : reached
            ? accent
            : AppColors.surface,
        border: Border.all(
          color: reached ? accent : AppColors.checkOff,
          width: 2,
        ),
      ),
      child: current
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
            )
          : reached
          ? const AppSvgIcon(
              AppIcon.check,
              size: 12,
              color: AppColors.navy,
              strokeWidth: 3,
            )
          : null,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                dot,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: nextReached ? accent : AppColors.cardRing,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: AppText.strong.copyWith(
                            color: bad
                                ? AppColors.danger
                                : reached
                                ? AppColors.ink
                                : AppColors.grey,
                            fontSize: current ? 15 : 14,
                          ),
                        ),
                      ),
                      if (reached && at != null)
                        Text(
                          dayTimeLabel(at!),
                          style: AppText.muted.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                  if (reached && hint.isNotEmpty)
                    Text(hint, style: AppText.muted.copyWith(height: 1.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.line, required this.pageId});
  final StoreOrderLine line;
  final String pageId;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: pageId.isEmpty
        ? null
        : () => context.push(Routes.product(pageId, line.productId)),
    child: Row(
      children: [
        _Thumb(line.image, size: 56, radius: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.strong,
              ),
              Text(
                line.price > 0
                    ? '${line.quantity} × ${storePrice(line.price)}'
                    : '× ${line.quantity}',
                style: AppText.muted,
              ),
            ],
          ),
        ),
        if (line.price > 0) ...[
          const SizedBox(width: 8),
          Text(
            storePrice(line.price * line.quantity),
            style: AppText.number.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});
  final AppIcon icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blueTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppSvgIcon(icon, size: 18, color: AppColors.blue),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.muted),
            Text(
              body,
              style: AppText.strong.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: strong
              ? AppText.strong.copyWith(fontSize: 15)
              : AppText.muted.copyWith(fontSize: 14),
        ),
      ),
      Text(
        value,
        style: AppText.number.copyWith(
          fontSize: strong ? 18 : 14,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          color: strong ? AppColors.blue : AppColors.ink,
        ),
      ),
    ],
  );
}

/// The page that sells the order. The store API has no page phone or chat for
/// store orders, so the card opens the page profile.
class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.name,
    required this.onOpen,
    this.image,
    this.rating,
  });
  final String name;
  final String? image;
  final double? rating;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => _Section(
    padding: 12,
    child: Row(
      children: [
        _Avatar(name: name, image: image, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.strong,
              ),
              Row(
                children: [
                  Text('الصفحة البائعة', style: AppText.muted),
                  if ((rating ?? 0) > 0) ...[
                    Text(
                      ' · ${rating!.toStringAsFixed(1)} ',
                      style: AppText.muted,
                    ),
                    const AppSvgIcon(
                      AppIcon.star,
                      size: 13,
                      color: AppColors.gold,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.blueTint,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(
                'شوف الصفحة',
                style: AppText.label.copyWith(color: AppColors.blue),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrderReportSheet extends ConsumerStatefulWidget {
  const _OrderReportSheet({required this.order});
  final StoreOrder order;

  @override
  ConsumerState<_OrderReportSheet> createState() => _OrderReportSheetState();
}

class _OrderReportSheetState extends ConsumerState<_OrderReportSheet> {
  static const _reasons = [
    ('mismatch', 'المنتج اللي وصلني مو مطابق'),
    ('fake', 'منتج مو أصلي'),
    ('abuse', 'تعامل مسيء من الصفحة'),
    ('other', 'شي ثاني'),
  ];
  final _text = TextEditingController();
  var _reason = 0;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final note = _text.text.trim();
    try {
      await ref.read(apiClientProvider).post<Object?>('/api/v1/reports', {
        'target': 'page',
        'targetId': widget.order.pageId,
        'reason': _reasons[_reason].$1,
        'text':
            '${widget.order.no}: ${note.isEmpty ? _reasons[_reason].$2 : note}',
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = storeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: AppSheet(
      children: [
        Text('بلّغ عن مشكلة بالطلب', style: AppText.big.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text('البلاغ يوصل لفريق دوّرلي، مو للصفحة.', style: AppText.muted),
        const SizedBox(height: 12),
        for (var i = 0; i < _reasons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioRow(
              label: _reasons[i].$2,
              on: i == _reason,
              onTap: () => setState(() => _reason = i),
            ),
          ),
        TextField(
          controller: _text,
          maxLines: 2,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'تفاصيل إضافية (اختياري)',
          ),
        ),
        if (_error != null) ...[
          Text(_error!, style: AppText.body.copyWith(color: AppColors.danger)),
          const SizedBox(height: 8),
        ],
        AppButton(
          _busy ? 'دا نرسل...' : 'دز البلاغ',
          icon: AppIcon.flag,
          onPressed: _busy ? null : _send,
        ),
      ],
    ),
  );
}

/// Delivered order line with its rate / edit action.
class _RateLine extends ConsumerWidget {
  const _RateLine({required this.line, required this.pageId});
  final StoreOrderLine line;
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myRatingProvider(line.productId)).value;
    return Row(
      children: [
        _Thumb(line.image, size: 48, radius: 12),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.strong.copyWith(fontSize: 13.5),
              ),
              if (mine?.stars != null)
                StarRow(value: mine!.stars!.toDouble(), size: 13),
            ],
          ),
        ),
        if (mine?.canRate == true)
          TextButton.icon(
            onPressed: () => showRateSheet(
              context,
              ref,
              productId: line.productId,
              productName: line.name,
              pageId: pageId,
            ),
            icon: const AppSvgIcon(
              AppIcon.star,
              size: 16,
              color: AppColors.gold,
            ),
            label: Text(
              mine!.stars == null ? 'قيّم' : 'عدّل',
              style: AppText.label.copyWith(color: AppColors.blue),
            ),
          ),
      ],
    );
  }
}
