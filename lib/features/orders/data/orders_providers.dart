import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/order.dart';
import 'api_orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => ApiOrdersRepository(ref.watch(apiClientProvider)),
);

final orderProvider = FutureProvider.autoDispose.family<OrderStatus, String>(
  (ref, id) => ref.watch(ordersRepositoryProvider).order(id),
);
