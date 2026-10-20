import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/live_request.dart';
import 'api_live_repository.dart';

final liveRepositoryProvider = Provider<LiveRequestRepository>(
  (ref) => ApiLiveRequestRepository(ref.watch(apiClientProvider)),
);

final liveRequestProvider = StreamProvider.autoDispose.family<LiveRequest, String>(
  (ref, id) => ref.watch(liveRepositoryProvider).watch(id),
);
