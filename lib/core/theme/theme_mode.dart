import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../storage/prefs.dart';

/// Light/dark is the user's choice from settings only; the device theme is
/// never followed. Default is light.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const key = 'display.theme';

  /// Older builds stored `display.night` as 0 auto, 1 on, 2 off.
  static const legacyKey = 'display.night';

  @override
  ThemeMode build() => read(ref.watch(sharedPrefsProvider));

  /// Stored choice; an explicit «مفعّل» from the old setting stays dark, the
  /// old «تلقائي» (follow device) becomes light. Anything else is light.
  static ThemeMode read(SharedPreferences prefs) {
    final stored = prefs.getString(key);
    if (stored != null) {
      return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    return prefs.getInt(legacyKey) == 1 ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  void set(ThemeMode mode) {
    final next = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(key, next == ThemeMode.dark ? 'dark' : 'light');
    prefs.remove(legacyKey);
    state = next;
  }

  void setDark(bool dark) => set(dark ? ThemeMode.dark : ThemeMode.light);

  void toggle() => setDark(!isDark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Settings label for the current mode.
extension ThemeModeLabel on ThemeMode {
  String get label => this == ThemeMode.dark ? 'مفعّل' : 'مطفي';
}
