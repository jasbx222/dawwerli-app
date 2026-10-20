import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/prefs.dart';

/// Where the API lives. Build-time default via `--dart-define=API_BASE_URL=…`
/// (emulator → host PC is 10.0.2.2); can be overridden at runtime from settings.
abstract final class ApiDefaults {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  static const livePoll = Duration(
    seconds: int.fromEnvironment('LIVE_POLL_SECONDS', defaultValue: 5),
  );
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
}

class ApiBaseUrl extends Notifier<String> {
  static const _k = 'api.baseUrl';

  @override
  String build() =>
      ref.watch(sharedPrefsProvider).getString(_k) ?? ApiDefaults.baseUrl;

  void set(String url) {
    final v = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (v.isEmpty) {
      ref.read(sharedPrefsProvider).remove(_k);
      state = ApiDefaults.baseUrl;
    } else {
      ref.read(sharedPrefsProvider).setString(_k, v);
      state = v;
    }
  }
}

final apiBaseUrlProvider = NotifierProvider<ApiBaseUrl, String>(ApiBaseUrl.new);
