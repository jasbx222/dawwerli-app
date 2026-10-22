import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../domain/offer.dart';
import 'api_offers_repository.dart';

final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => ApiOffersRepository(ref.watch(apiClientProvider)),
);

/// How often an open offers board re-reads the server.
final offersPollProvider = Provider<Duration>((_) => ApiDefaults.livePoll);

/// The customer's offers board. Home keeps it alive under every pushed
/// screen, so it must never serve a stale copy: it re-reads the server on a
/// timer while someone is watching, and right away when a screen comes back
/// to it (compare, details, or home after a pop). Without this, offers sent
/// after home first loaded never reached the compare or details screens.
final offersProvider = FutureProvider.autoDispose.family<OffersBoard, String>((
  ref,
  id,
) async {
  var alive = true;
  var paused = false;
  ref.onDispose(() => alive = false);
  ref.onCancel(() => paused = true);
  ref.onResume(() {
    if (!paused) return;
    paused = false;
    // Life-cycle callbacks may not touch the ref directly.
    scheduleMicrotask(() {
      if (alive) ref.invalidateSelf();
    });
  });
  final board = await ref.watch(offersRepositoryProvider).offers(id);
  final poll = Timer(ref.watch(offersPollProvider), ref.invalidateSelf);
  ref.onDispose(poll.cancel);
  return board;
});

final selectionProvider = FutureProvider.autoDispose.family<Selection?, String>(
  (ref, id) => ref.watch(offersRepositoryProvider).selection(id),
);
