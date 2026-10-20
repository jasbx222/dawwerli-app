import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded once in `main()` and injected with an override, so providers can
/// read local storage synchronously.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPrefsProvider in main()'),
);
