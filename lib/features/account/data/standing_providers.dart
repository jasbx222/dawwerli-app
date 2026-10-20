import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class Strike {
  const Strike(this.reason, this.at, this.frozen);
  final String reason;
  final DateTime at;
  final bool frozen;
}

/// GET /api/v1/me/standing.
class Standing {
  const Standing({
    required this.strikes,
    required this.strikesForBan,
    required this.bannedUntil,
    required this.permanent,
  });
  final List<Strike> strikes;
  final int strikesForBan;
  final DateTime? bannedUntil;
  final bool permanent;
}

/// One dispute/appeal (GET /api/v1/disputes).
class DisputeView {
  const DisputeView({
    required this.id,
    required this.type,
    required this.status,
    required this.text,
    required this.createdAt,
    required this.decideBy,
    this.orderId,
    this.decision,
  });
  final String id;
  final String type;

  /// open · underReview · accepted · rejected
  final String status;
  final String text;
  final DateTime createdAt;
  final DateTime decideBy;
  final String? orderId;
  final String? decision;

  bool get decided => status == 'accepted' || status == 'rejected';

  /// Short tracking number shown to the user.
  String get trackNo => 'CMP-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';
}

DisputeView disputeFromJson(Map<String, dynamic> d) => DisputeView(
  id: d.s('id'),
  type: d.s('type'),
  status: d.s('status'),
  text: d.s('text'),
  createdAt: d.t('createdAt'),
  decideBy: d.t('decideBy'),
  orderId: d.os('orderId'),
  decision: d.os('decision'),
);

final standingProvider = FutureProvider.autoDispose<Standing>((ref) async {
  final j = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/api/v1/me/standing');
  return Standing(
    strikes: [
      for (final s in j.l('strikes')) Strike(s.s('reason'), s.t('at'), s.b('frozen')),
    ],
    strikesForBan: j.i('strikesForBan'),
    bannedUntil: j.ot('bannedUntil'),
    permanent: j.b('permanent'),
  );
});

final myDisputesProvider = FutureProvider.autoDispose<List<DisputeView>>((ref) async {
  final list = asList(await ref.watch(apiClientProvider).get<List<dynamic>>('/api/v1/disputes'));
  return [for (final d in list) disputeFromJson(d)];
});

final disputeProvider = FutureProvider.autoDispose.family<DisputeView, String>((ref, id) async =>
    disputeFromJson(await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/api/v1/disputes/$id')));
