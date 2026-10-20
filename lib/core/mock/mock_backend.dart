import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MockRequestStatus { open, cancelled }

/// One customer request as the mock server stores it. Times are absolute so
/// every screen counts down from the same expiry (like the real API's
/// `closes_at` / `widens_at`).
class MockRequestRecord {
  MockRequestRecord({
    required this.id,
    required this.title,
    required this.image,
    required this.homeImage,
    required this.maxPrice,
    required this.closesAt,
    required this.widensAt,
    this.offerPrices = const [],
    this.status = MockRequestStatus.open,
  });

  final String id;
  final String title;
  final String image;
  final String homeImage;
  int maxPrice;
  final DateTime closesAt;
  final DateTime widensAt;
  final List<int> offerPrices;
  MockRequestStatus status;
}

/// In-memory stand-in for the requests API shared by the home, post and live
/// mock repositories, so a cancel or price change on one screen shows up on the others.
class MockBackend {
  MockBackend({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final now = _clock();
    requests['r1'] = MockRequestRecord(
      id: 'r1',
      title: 'حذاء رياضي أسود · 43',
      image: 'assets/images/mock/cat_shoes_1.webp',
      homeImage: 'assets/images/mock/shoe.jpg',
      maxPrice: 45000,
      closesAt: now.add(const Duration(hours: 23, minutes: 41, seconds: 59)),
      widensAt: now.add(
        const Duration(minutes: 11, seconds: 20, milliseconds: 900),
      ),
      offerPrices: const [35000, 39000, 42000],
    );
  }

  final DateTime Function() _clock;
  final requests = <String, MockRequestRecord>{};
  final _changes = StreamController<String>.broadcast();
  int _seq = 0;

  DateTime now() => _clock();

  /// Emits the id of every request that changed.
  Stream<String> get changes => _changes.stream;

  MockRequestRecord create({
    required String title,
    required String image,
    required int maxPrice,
  }) {
    final now = _clock();
    final r = MockRequestRecord(
      id: 'req_mock_${++_seq}',
      title: title,
      image: image,
      homeImage: image,
      maxPrice: maxPrice,
      closesAt: now.add(const Duration(hours: 24)),
      widensAt: now.add(const Duration(minutes: 15)),
    );
    requests[r.id] = r;
    _changes.add(r.id);
    return r;
  }

  void cancel(String id) {
    requests[id]?.status = MockRequestStatus.cancelled;
    _changes.add(id);
  }

  void raisePrice(String id, int newMax) {
    requests[id]?.maxPrice = newMax;
    _changes.add(id);
  }

  /// Newest open request (home shows one live card).
  MockRequestRecord? get latestOpen {
    final open = requests.values
        .where((r) => r.status == MockRequestStatus.open)
        .toList();
    return open.isEmpty ? null : open.last;
  }
}

final mockBackendProvider = Provider<MockBackend>((ref) => MockBackend());
