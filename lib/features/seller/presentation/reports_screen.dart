import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_page.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';

class _Sale {
  const _Sale({
    required this.title,
    required this.qty,
    required this.amount,
    required this.orderNo,
    this.image = '',
    this.offerId,
  });
  final String title;
  final int qty;
  final int amount;
  final String orderNo;
  final String image;
  final String? offerId;
}

class _Rank {
  const _Rank(this.name, this.qty, this.amount, this.image);
  final String name;
  final int qty;
  final int amount;
  final String image;
}

class _SellerReport {
  const _SellerReport({
    required this.orderCount,
    required this.orderAmount,
    required this.revenue,
    required this.best,
    required this.orders,
  });

  final int orderCount;
  final int orderAmount;
  final int revenue;
  final List<_Rank> best;
  final List<_Sale> orders;

  factory _SellerReport.from(List<_Sale> pageOrders, _StoreBundle store) {
    final orders = [...pageOrders, ...store.orders];
    final amount = orders.fold<int>(0, (s, o) => s + o.amount);
    final ranks = <String, _Rank>{};
    void add(_Sale o) {
      if (o.title.isEmpty) return;
      final prev = ranks[o.title];
      ranks[o.title] = _Rank(
        o.title,
        (prev?.qty ?? 0) + (o.qty <= 0 ? 1 : o.qty),
        (prev?.amount ?? 0) + o.amount,
        prev?.image.isNotEmpty == true ? prev!.image : o.image,
      );
    }

    for (final o in pageOrders) {
      add(o);
    }
    for (final o in store.lines) {
      add(o);
    }
    final best = ranks.values.toList()
      ..sort((a, b) {
        final byQty = b.qty.compareTo(a.qty);
        return byQty != 0 ? byQty : b.amount.compareTo(a.amount);
      });
    return _SellerReport(
      orderCount: orders.length,
      orderAmount: amount,
      revenue: amount,
      best: best.take(5).toList(),
      orders: orders,
    );
  }
}

class _StoreBundle {
  const _StoreBundle({this.orders = const [], this.lines = const []});
  final List<_Sale> orders;
  final List<_Sale> lines;
}

final _sellerReportProvider = FutureProvider.autoDispose<_SellerReport>((ref) async {
  final offers = ref.watch(sellerProvider).offers;
  final api = ref.watch(apiClientProvider);
  final pageOrders = await _pageOrders(api, offers);
  final storeOrders = await _storeOrders(api);
  return _SellerReport.from(pageOrders, storeOrders);
});

Future<List<_Sale>> _pageOrders(ApiClient api, List<SellerOffer> offers) async {
  try {
    final rows = _rows(await api.get<Object?>('/api/v1/pages/me/orders'));
    final parsed = [
      for (final o in rows)
        if (o.s('state').isEmpty || o.s('state') == 'chosen') ?_pageSale(o),
    ];
    if (parsed.isNotEmpty) return parsed;
  } on ApiException {
    // The offers list already has the completed deals.
  }
  return [
    for (final o in offers)
      if (o.state == OfferState.chosen)
        _Sale(
          title: o.title,
          qty: 1,
          amount: o.price,
          orderNo: o.orderNo ?? '',
          image: o.image,
          offerId: o.id,
        ),
  ];
}

_Sale? _pageSale(Map<String, dynamic> o) {
  final offer = o.om('offer');
  final title = _firstText(o, const ['title', 'itemTitle', 'name']) ??
      (offer == null ? null : _firstText(offer, const ['title', 'pageName']));
  final amount = _money(o, const ['price', 'subtotal']) ??
      (offer == null ? null : _money(offer, const ['price'])) ??
      0;
  final no = o.os('orderNo') ?? o.os('no') ?? '';
  if ((title == null || title.isEmpty) && no.isEmpty && amount == 0) return null;
  return _Sale(
    title: title ?? '',
    qty: 1,
    amount: amount,
    orderNo: no,
    image: o.os('image') ?? offer?.os('image') ?? '',
    offerId: o.os('offerId'),
  );
}

Future<_StoreBundle> _storeOrders(ApiClient api) async {
  try {
    final rows = _rows(
      await api.get<Object?>(
        '/api/v1/pages/me/store-orders',
        query: {'page': 1, 'pageSize': 50},
      ),
    );
    final orders = <_Sale>[];
    final lines = <_Sale>[];
    for (final row in rows) {
      final o = row.om('order') ?? row;
      final status = o.s('status');
      if (status == 'cancelled' || status == 'rejected') continue;
      final items = o.l('items');
      final no = o.s('no');
      if (items.isEmpty) {
        final title = _firstText(o, const ['title', 'name']) ?? no;
        if (title.isEmpty && o.i('subtotal') == 0) continue;
        orders.add(_Sale(title: title, qty: 1, amount: o.i('subtotal'), orderNo: no));
        continue;
      }
      var qty = 0;
      var priced = 0;
      final itemLines = <_Sale>[];
      for (final item in items) {
        final n = item.i('quantity') <= 0 ? 1 : item.i('quantity');
        final unit = item.containsKey('unitPrice')
            ? item.i('unitPrice')
            : (item.containsKey('price') ? item.i('price') : 0);
        qty += n;
        priced += unit * n;
        itemLines.add(
          _Sale(
            title: item.s('name'),
            qty: n,
            amount: unit * n,
            orderNo: no,
            image: item.os('imageUrl') ?? item.os('image') ?? '',
          ),
        );
      }
      final subtotal = o.i('subtotal');
      if (priced == 0 && subtotal > 0 && itemLines.isNotEmpty) {
        itemLines[0] = _Sale(
          title: itemLines.first.title,
          qty: itemLines.first.qty,
          amount: subtotal,
          orderNo: no,
          image: itemLines.first.image,
        );
      }
      final named = itemLines.where((l) => l.title.isNotEmpty).toList();
      lines.addAll(named);
      orders.add(
        _Sale(
          title: named.isEmpty ? no : named.first.title,
          qty: qty <= 0 ? 1 : qty,
          amount: subtotal > 0 ? subtotal : priced,
          orderNo: no,
          image: named.isEmpty ? '' : named.first.image,
        ),
      );
    }
    return _StoreBundle(orders: orders, lines: lines);
  } on ApiException {
    return const _StoreBundle();
  }
}

List<Map<String, dynamic>> _rows(Object? data) {
  if (data is List) return asList(data);
  if (data is Map) {
    final items = data['items'];
    if (items is List) return asList(items);
  }
  return const [];
}

String? _firstText(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j.os(k);
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

int? _money(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] is num) return j.i(k);
  }
  return null;
}

String _iqd(int n) => '${thousands(n)} د.ع';

/// Page reports: best sellers, order count and amount, and the revenue of those orders.
class SellerReportsScreen extends ConsumerWidget {
  const SellerReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(_sellerReportProvider);
    return AppPage(
      title: 'التقارير والطلبات',
      subtitle: 'الصفقات المكتملة وطلبات المتجر',
      children: [
        report.when(
          loading: () => Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          ),
          error: (e, _) => Gap(
            Text('ما قدرنا نحمّل التقارير', style: AppText.body),
          ),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Gap(
                AppCard(
                  child: Row(
                    children: [
                      _Stat('${r.orderCount}', 'عدد الطلبات'),
                      _Stat(_iqd(r.orderAmount), 'مبلغ الطلبات'),
                      _Stat(_iqd(r.revenue), 'الإيراد'),
                    ],
                  ),
                ),
              ),
              const SectionLabel('المنتجات الأعلى مبيعاً'),
              if (r.best.isEmpty)
                Gap(
                  AppCard(
                    child: Text('ماكو مبيعات بعد', style: AppText.muted),
                  ),
                )
              else
                Gap(
                  AppCard(
                    insets: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < r.best.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: AppColors.divider),
                          _BestRow(r.best[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              const SectionLabel('الطلبات'),
              if (r.orders.isEmpty)
                Gap(
                  AppCard(
                    child: Text('ماكو طلبات مكتملة بعد', style: AppText.muted),
                  ),
                )
              else
                Gap(
                  AppCard(
                    insets: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < r.orders.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: AppColors.divider),
                          _OrderRow(
                            r.orders[i],
                            onTap: r.orders[i].offerId == null
                                ? null
                                : () => context.push(
                                    Routes.sellerChosen(r.orders[i].offerId!),
                                  ),
                          ),
                        ],
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
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppText.number.copyWith(fontSize: 16, color: AppColors.blue),
          ),
        ),
        Text(label, textAlign: TextAlign.center, style: AppText.muted),
      ],
    ),
  );
}

class _BestRow extends StatelessWidget {
  const _BestRow(this.rank);
  final _Rank rank;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        _Thumb(rank.image, rank.name),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rank.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.strong),
              Text('${rank.qty} مبيع', style: AppText.muted),
            ],
          ),
        ),
        Text(_iqd(rank.amount), style: AppText.number.copyWith(color: AppColors.blue)),
      ],
    ),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow(this.sale, {this.onTap});
  final _Sale sale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _Thumb(sale.image, sale.title),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.title.isEmpty ? 'طلب' : sale.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.strong,
                ),
                Text(
                  [
                    if (sale.orderNo.isNotEmpty) '#${sale.orderNo}',
                    if (sale.qty > 1) '× ${sale.qty}',
                  ].join(' · '),
                  style: AppText.muted,
                ),
              ],
            ),
          ),
          Text(_iqd(sale.amount), style: AppText.number.copyWith(color: AppColors.blue)),
        ],
      ),
    ),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.image, this.name);
  final String image;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.blueTint,
      borderRadius: BorderRadius.circular(12),
      image: image.isEmpty
          ? null
          : DecorationImage(image: appImage(image), fit: BoxFit.cover),
    ),
    alignment: Alignment.center,
    child: image.isEmpty
        ? Text(
            name.characters.firstOrNull ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
            ),
          )
        : null,
  );
}
