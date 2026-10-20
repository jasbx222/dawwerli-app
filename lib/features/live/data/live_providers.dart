import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_backend.dart';
import '../domain/live_request.dart';
import 'mock_live_repository.dart';

final liveRepositoryProvider = Provider<LiveRequestRepository>(
  (ref) => MockLiveRequestRepository(ref.watch(mockBackendProvider)),
);

final liveRequestProvider = StreamProvider.family<LiveRequest, String>(
  (ref, id) => ref.watch(liveRepositoryProvider).watch(id),
);
