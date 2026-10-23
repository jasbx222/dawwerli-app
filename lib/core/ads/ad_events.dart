import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/token_store.dart';

/// Impressions and clicks for paid placements: `POST /api/v1/ads/{id}/events`.
/// The server counts one event per device per hour, so repeats are harmless.
/// Tracking must never break the screen, so every failure is swallowed.
class AdEvents {
  AdEvents(this.api, this.tokens);
  final ApiClient api;
  final TokenStore tokens;

  /// Impressions already sent this hour (the server's dedupe window).
  final _seen = <String>{};

  Future<void> impression(String adId) async {
    final now = DateTime.now().toUtc();
    final key = '$adId@${now.year}-${now.month}-${now.day}-${now.hour}';
    if (adId.isEmpty || !_seen.add(key)) return;
    await _send(adId, 'impression');
  }

  Future<void> click(String adId) => _send(adId, 'click');

  Future<void> _send(String adId, String type) async {
    if (adId.isEmpty) return;
    try {
      await api.post<Object?>('/api/v1/ads/$adId/events', {
        'type': type,
        'deviceId': await tokens.device(newId),
      });
    } on Object {
      // Offline or ad already ended: the count is best-effort.
    }
  }
}

final adEventsProvider = Provider<AdEvents>(
  (ref) =>
      AdEvents(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)),
);

/// Counts a click on a paid card (when [adId] is set), then runs [onTap].
void trackAdTap(BuildContext context, String? adId, VoidCallback? onTap) {
  if (adId != null && adId.isNotEmpty) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adEventsProvider).click(adId);
  }
  onTap?.call();
}

/// Counts an impression once the ad has stayed on screen for [after].
/// Ads without an id (organic content) are passed through untouched.
class AdImpression extends ConsumerStatefulWidget {
  const AdImpression({
    super.key,
    required this.adId,
    required this.child,
    this.after = const Duration(seconds: 1),
  });
  final String? adId;
  final Widget child;
  final Duration after;

  @override
  ConsumerState<AdImpression> createState() => _AdImpressionState();
}

class _AdImpressionState extends ConsumerState<AdImpression> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(AdImpression old) {
    super.didUpdateWidget(old);
    if (old.adId != widget.adId) _arm();
  }

  void _arm() {
    _timer?.cancel();
    final id = widget.adId;
    if (id == null || id.isEmpty) return;
    _timer = Timer(widget.after, () {
      if (mounted) ref.read(adEventsProvider).impression(id);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
