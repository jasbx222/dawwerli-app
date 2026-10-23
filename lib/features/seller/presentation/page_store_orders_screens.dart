import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/loading_block.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/order_map.dart';
import '../../../core/widgets/pill.dart';
import '../../store/data/store_data.dart';
import '../../store/presentation/store_order_screens.dart'
    show OrderStatusPill, storeStatusLabel;
import '../../tracking/courier_tracking.dart';
import '../../tracking/tracking_widgets.dart';
import '../data/page_store_orders.dart';
import 'couriers_screen.dart';
import 'widgets/page_side_widgets.dart';
import 'widgets/seller_nav.dart';
import 'widgets/seller_widgets.dart';

const _pageSize = 20;

String _payLabel(String method) => switch (method.toLowerCase()) {
  'cash' || 'cod' || 'cashondelivery' => 'كاش عند الاستلام',
  '' => '',
  _ => 'دفع إلكتروني',
};

/// «طلباتي» — product orders customers placed with this page's store.
class SellerStoreOrdersScreen extends ConsumerStatefulWidget {
  const SellerStoreOrdersScreen({super.key});

  @override
  ConsumerState<SellerStoreOrdersScreen> createState() => _OrdersState();
}

class _OrdersState extends ConsumerState<SellerStoreOrdersScreen>
    with WidgetsBindingObserver, PagePolling {
  StoreOrderFilter _filter = StoreOrderFilter.all;
  List<PageStoreOrder> _items = const [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _more = false;
  Object? _error;

  PageStoreOrdersRepo get _repo => ref.read(pageStoreOrdersRepoProvider);

  @override
  void initState() {
    super.initState();
    startPolling();
    _reload();
  }

  Future<void> _reload() async {
    final f = _filter;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.list(f, pageSize: _pageSize);
      if (!mounted || f != _filter) return;
      setState(() {
        _items = p.items;
        _total = p.total;
        _page = 1;
      });
    } catch (e) {
      if (mounted && f == _filter) setState(() => _error = e);
    } finally {
      if (mounted && f == _filter) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final f = _filter;
    setState(() => _more = true);
    try {
      final p = await _repo.list(f, page: _page + 1, pageSize: _pageSize);
      if (!mounted || f != _filter) return;
      final have = {for (final o in _items) o.order.id};
      setState(() {
        _items = [
          ..._items,
          ...p.items.where((o) => !have.contains(o.order.id)),
        ];
        _total = p.total;
        _page++;
      });
    } catch (_) {
      if (mounted) showAppToast(context, 'ما كدرنا نجيب أكثر، جرّب مرة ثانية');
    } finally {
      if (mounted) setState(() => _more = false);
    }
  }

  @override
  Future<void> poll() async {
    if (_loading || _more || _error != null) return;
    final f = _filter;
    final n = _items.length.clamp(_pageSize, 50);
    try {
      final p = await _repo.list(f, pageSize: n);
      if (!mounted || f != _filter) return;
      final fresh = {for (final o in p.items) o.order.id};
      setState(() {
        _items = [
          ...p.items,
          ..._items.skip(n).where((o) => !fresh.contains(o.order.id)),
        ];
        _total = p.total;
      });
    } catch (_) {}
  }

  void _pick(StoreOrderFilter f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _items = const [];
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'طلباتي',
    showBack: false,
    trailing: _total > 0
        ? Pill(
            '$_total طلب',
            bg: AppColors.white.withValues(alpha: .18),
            fg: AppColors.white,
          )
        : null,
    nav: const SellerNav(SellerTab.orders),
    onRefresh: _reload,
    children: [
      ChipRow(
        children: [
          for (final f in StoreOrderFilter.values)
            choiceChip(f.label, f == _filter, () => _pick(f)),
        ],
      ),
      ..._body(),
    ],
  );

  List<Widget> _body() {
    if (_loading && _items.isEmpty) return const [ListSkeleton()];
    if (_error != null && _items.isEmpty) {
      return [Gap(RetryCard(error: _error!, onRetry: _reload))];
    }
    if (_items.isEmpty) {
      return [
        Gap(
          EmptyStateCard(
            icon: AppIcon.bag,
            title: _filter == StoreOrderFilter.all
                ? 'ماكو طلبات بعد'
                : 'ماكو طلبات ${_filter.label}',
            body: 'لمن زبون يطلب منتج من متجرك، الطلب يطلع هنا وتكدر تقبله وتتابعه.',
          ),
        ),
      ];
    }
    return [
      ResponsiveCards(
        children: [
          for (final o in _items)
            _OrderCard(
              o,
              onTap: () async {
                await context.push(Routes.sellerOrder(o.order.id));
                if (mounted) poll();
              },
            ),
        ],
      ),
      if (_items.length < _total)
        Gap(
          AppButton(
            _more ? 'دنجيب...' : 'حمّل أكثر',
            compact: true,
            variant: AppButtonVariant.ghost,
            icon: AppIcon.refresh,
            onPressed: _more ? null : _loadMore,
          ),
        ),
      const SizedBox(height: 8),
    ];
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.o, {required this.onTap});
  final PageStoreOrder o;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final order = o.order;
    final pay = _payLabel(order.payment);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'طلب ${order.no}',
                    style: AppText.strong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OrderStatusPill(order.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                AppSvgIcon(AppIcon.person, color: AppColors.grey, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    o.customerName?.isNotEmpty == true
                        ? o.customerName!
                        : 'زبون',
                    style: AppText.muted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (order.createdAt != null)
                  Text(
                    agoLabel(order.createdAt!.toLocal()),
                    style: AppText.muted,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.items.join('، '),
              style: AppText.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  iqd(order.subtotal),
                  style: AppText.strong.copyWith(color: AppColors.blue),
                ),
                if (pay.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  PillTone.stone.pill(pay),
                ],
                const Spacer(),
                if (order.isNew)
                  PillTone.gold.pill('يحتاج ردّك', icon: AppIcon.clock),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One store order: items, customer, timeline and the next allowed moves.
class SellerStoreOrderScreen extends ConsumerStatefulWidget {
  const SellerStoreOrderScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<SellerStoreOrderScreen> createState() => _OrderState();
}

class _OrderState extends ConsumerState<SellerStoreOrderScreen>
    with WidgetsBindingObserver, PagePolling {
  PageStoreOrder? _o;
  Object? _error;
  bool _busy = false;

  PageStoreOrdersRepo get _repo => ref.read(pageStoreOrdersRepoProvider);

  @override
  void initState() {
    super.initState();
    startPolling();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await _repo.get(widget.orderId);
      if (!mounted) return;
      setState(() {
        _o = o;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Future<void> poll() async {
    if (!_busy) await _load();
  }

  Future<void> _move(String status, {String? reason, String? courierId}) async {
    setState(() => _busy = true);
    try {
      final o = await _repo.move(
        widget.orderId,
        status,
        reason: reason,
        courierId: courierId,
      );
      if (!mounted) return;
      setState(() => _o = o);
      showAppToast(context, 'صار الطلب ${storeStatusLabel(o.order.status)}');
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        pageOrderError(e, 'ما تكدر تغيّر حالة الطلب هسه'),
        icon: AppIcon.alert,
      );
      _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerateLink() async {
    try {
      final link = await ref
          .read(courierTrackingRepoProvider)
          .regenerate(widget.orderId);
      if (!mounted) return;
      setState(() => _o = _o?.withLink(link));
      showAppToast(context, 'سوّينا رابط جديد، دزه للمندوب');
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        pageOrderError(e, 'ما قدرنا نسوّي رابط جديد هسه'),
        icon: AppIcon.alert,
      );
    }
  }

  Future<void> _outForDelivery() async {
    final c = await CourierPickerSheet.show(context);
    if (c != null && mounted) await _move('out_for_delivery', courierId: c.id);
  }

  void _withReason(String status) {
    final reject = status == 'rejected';
    final reasons = reject
        ? const ['المنتج خلص', 'ما نوصل لهالمنطقة', 'السعر تغيّر', 'سبب ثاني']
        : const [
            'الزبون ما يرد',
            'الزبون لغى الطلب',
            'مشكلة بالتوصيل',
            'سبب ثاني',
          ];
    ReasonSheet.show(
      context,
      title: reject ? 'ترفض الطلب؟' : 'تلغي الطلب؟',
      sub: 'الزبون يشوف السبب',
      reasons: reasons,
      onSend: (i) => _move(status, reason: reasons[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _o;
    return AppPage(
      title: o == null ? 'تفاصيل الطلب' : 'طلب ${o.order.no}',
      onRefresh: _load,
      bottom: o == null ? null : _actions(o.order),
      children: [
        if (o == null && _error != null)
          Gap(RetryCard(error: _error!, onRetry: _load))
        else if (o == null)
          const Gap(LoadingBlock())
        else
          ..._details(o),
      ],
    );
  }

  Widget? _actions(StoreOrder order) {
    final next = nextStoreStatuses(order.status);
    if (next.isEmpty) return null;
    Widget btn(String s) => switch (s) {
      'accepted' => AppButton(
        'اقبل الطلب',
        icon: AppIcon.check,
        onPressed: _busy ? null : () => _move(s),
      ),
      'out_for_delivery' => AppButton(
        'طلّع للتوصيل',
        variant: AppButtonVariant.navy,
        icon: AppIcon.truck,
        onPressed: _busy ? null : _outForDelivery,
      ),
      'delivered' => AppButton(
        'وصل للزبون',
        icon: AppIcon.check,
        onPressed: _busy ? null : () => _move(s),
      ),
      'rejected' => AppButton(
        'ارفض',
        variant: AppButtonVariant.ghost,
        onPressed: _busy ? null : () => _withReason(s),
      ),
      _ => AppButton(
        'ألغِ',
        variant: AppButtonVariant.ghost,
        onPressed: _busy ? null : () => _withReason(s),
      ),
    };
    return Row(
      children: [
        Expanded(flex: 2, child: btn(next[0])),
        const SizedBox(width: 10),
        Expanded(child: btn(next[1])),
      ],
    );
  }

  List<Widget> _details(PageStoreOrder o) {
    final order = o.order;
    final pay = _payLabel(order.payment);
    final phone = o.customerPhone;
    return [
      Gap(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'طلب ${order.no}',
                      style: AppText.strong.copyWith(fontSize: 17),
                    ),
                  ),
                  OrderStatusPill(order.status),
                ],
              ),
              if (order.isOffer || order.disputed) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (order.isOffer)
                      PillTone.blue.pill('طلب من عرض', icon: AppIcon.target),
                    if (order.disputed)
                      PillTone.red.pill(
                        _dealLabel(order.dealStatus),
                        icon: AppIcon.alert,
                      ),
                  ],
                ),
              ],
              if (order.createdAt != null)
                Text(
                  'انطلب ${dayTimeLabel(order.createdAt!.toLocal())}',
                  style: AppText.muted,
                ),
              if (order.reason?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  'السبب: ${order.reason}',
                  style: AppText.muted.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      const SectionLabel('الزبون'),
      Gap(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoRow(
                AppIcon.person,
                o.customerName?.isNotEmpty == true ? o.customerName! : 'زبون',
              ),
              if (phone != null && phone.isNotEmpty)
                _InfoRow(
                  AppIcon.phone,
                  phone,
                  ltr: true,
                  action: 'اتصل',
                  onAction: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                ),
              if (order.address.isNotEmpty)
                _InfoRow(AppIcon.pin, order.address),
              if (order.location?.note?.isNotEmpty == true)
                _InfoRow(AppIcon.flag, order.location!.note!),
              if (order.note?.isNotEmpty == true)
                _InfoRow(AppIcon.clipboardList, order.note!),
              if (order.location case final pin?) ...[
                const SizedBox(height: 6),
                OrderPinMap(latitude: pin.latitude, longitude: pin.longitude),
              ],
              const SizedBox(height: 10),
              Text(
                phone != null && phone.isNotEmpty
                    ? 'الرقم يبين هنا بس، وينشال من الطلب بعد ما يخلص.'
                    : order.active
                    ? 'رقم الزبون يبين داخل الطلب بس ما دام الطلب شغّال'
                    : 'رقم الزبون وعنوانه انشالوا بعد ما خلص الطلب',
                style: AppText.muted,
              ),
            ],
          ),
        ),
      ),
      if (order.courier case final c?) ...[
        const SectionLabel('المندوب'),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoRow(AppIcon.truck, c.name),
                _InfoRow(AppIcon.phone, c.phone, ltr: true),
                Text(
                  'الزبون يشوف اسم المندوب ورقمه داخل طلبه.',
                  style: AppText.muted,
                ),
              ],
            ),
          ),
        ),
      ],
      if (o.trackingLink case final link?) ...[
        const SectionLabel('رابط تتبع المندوب'),
        Gap(
          AppCard(
            child: CourierLinkCard(link: link, onRegenerate: _regenerateLink),
          ),
        ),
      ],
      if (order.status == 'out_for_delivery')
        LiveCourierSection(
          key: ValueKey('courier-${order.id}'),
          storeOrderId: order.id,
          pinLatitude: order.location?.latitude,
          pinLongitude: order.location?.longitude,
          forPage: true,
          wrap: (child) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('وين وصل المندوب'),
              Gap(AppCard(child: child)),
            ],
          ),
        ),
      const SectionLabel('المنتجات'),
      Gap(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final l in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.name, style: AppText.body)),
                      Text('× ${l.quantity}', style: AppText.muted),
                      const SizedBox(width: 12),
                      Text(iqd(l.price * l.quantity), style: AppText.strong),
                    ],
                  ),
                ),
              Divider(color: AppColors.cardRing, height: 16),
              Row(
                children: [
                  Expanded(child: Text('المجموع', style: AppText.strong)),
                  Text(
                    iqd(order.subtotal),
                    style: AppText.strong.copyWith(
                      color: AppColors.blue,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              if (pay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('الدفع: $pay', style: AppText.muted),
                ),
            ],
          ),
        ),
      ),
      const SectionLabel('مراحل الطلب'),
      Gap(AppCard(child: _Timeline(order.history))),
      const SizedBox(height: 12),
    ];
  }
}

String _dealLabel(String? deal) => switch (deal) {
  'mismatch' => 'الزبون كال الغرض مو مطابق',
  'notDelivered' => 'الزبون كال ما وصله',
  _ => 'بيه بلاغ عند الإدارة',
};

class _InfoRow extends StatelessWidget {
  const _InfoRow(
    this.icon,
    this.text, {
    this.ltr = false,
    this.action,
    this.onAction,
  });
  final AppIcon icon;
  final String text;
  final bool ltr;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: AppSvgIcon(icon, color: AppColors.grey, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.body,
            textDirection: ltr ? TextDirection.ltr : null,
            // LTR numbers still sit on the RTL start (right) edge.
            textAlign: ltr ? TextAlign.right : TextAlign.start,
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppSvgIcon(
                    AppIcon.phone,
                    color: AppColors.blue,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action!,
                    style: AppText.strong.copyWith(color: AppColors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline(this.steps);
  final List<StoreOrderStep> steps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 18,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == steps.length - 1
                            ? AppColors.gold
                            : AppColors.blue,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(width: 2, color: AppColors.cardRing),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          storeStatusLabel(steps[i].status),
                          style: AppText.strong,
                        ),
                      ),
                      if (steps[i].at != null)
                        Text(
                          dayTimeLabel(steps[i].at!.toLocal()),
                          style: AppText.muted,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
