import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.route,
    required this.at,
    required this.read,
  });
  final String title;
  final String body;

  /// In-app route the notification opens (empty = nothing to open).
  final String route;
  final DateTime at;
  final bool read;
}

/// GET /api/v1/notifications (newest first); opening the tab marks all as read.
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final j = await api.get<Map<String, dynamic>>('/api/v1/notifications');
  final items = [
    for (final n in j.l('items'))
      AppNotification(
        title: n.s('title'),
        body: n.s('body'),
        route: n.s('route'),
        at: n.t('at'),
        read: n.b('read'),
      ),
  ];
  if (items.any((n) => !n.read)) await api.post<void>('/api/v1/notifications/read-all');
  return items;
});
