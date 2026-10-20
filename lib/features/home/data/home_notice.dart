import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot notice shown over home (e.g. after cancelling a request).
class HomeNotice extends Notifier<String?> {
  @override
  String? build() => null;
  void show(String text) => state = text;
  void clear() => state = null;
}

final homeNoticeProvider = NotifierProvider<HomeNotice, String?>(
  HomeNotice.new,
);
