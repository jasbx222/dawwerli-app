import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';
import 'mock_orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => MockOrdersRepository(),
);

final orderProvider = FutureProvider.autoDispose.family<OrderStatus, String>(
  (ref, id) => ref.watch(ordersRepositoryProvider).order(id),
);
