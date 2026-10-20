import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/live_request.dart';
import 'mock_live_repository.dart';

final liveRepositoryProvider = Provider<LiveRequestRepository>(
  (ref) => const MockLiveRequestRepository(),
);

final liveRequestProvider = StreamProvider.family<LiveRequest, String>(
  (ref, id) => ref.watch(liveRepositoryProvider).watch(id),
);
