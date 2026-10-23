import 'package:dawwerli/core/storage/prefs.dart';
import 'package:dawwerli/core/theme/app_colors.dart';
import 'package:dawwerli/core/theme/app_theme.dart';
import 'package:dawwerli/core/theme/theme_mode.dart';
import 'package:dawwerli/core/widgets/app_toggle.dart';
import 'package:dawwerli/core/widgets/theme_mode_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, SharedPreferences)> _container(
  Map<String, Object> stored,
) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return (c, prefs);
}

void main() {
  tearDown(() => AppColors.dark = false);

  test('defaults to light on a fresh install', () async {
    final (c, _) = await _container({});
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('device dark mode is ignored: old «تلقائي» becomes light', () async {
    final (c, _) = await _container({'display.night': 0});
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('an explicit old «مفعّل» stays dark', () async {
    final (c, _) = await _container({'display.night': 1});
    expect(c.read(themeModeProvider), ThemeMode.dark);
  });

  test('the choice is saved and read back on the next start', () async {
    final (c, prefs) = await _container({'display.night': 0});
    c.read(themeModeProvider.notifier).setDark(true);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString(ThemeModeNotifier.key), 'dark');
    expect(prefs.containsKey(ThemeModeNotifier.legacyKey), isFalse);

    // New process: same storage, fresh container.
    final next = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(next.dispose);
    expect(next.read(themeModeProvider), ThemeMode.dark);
    expect(ThemeModeNotifier.read(prefs), ThemeMode.dark);

    next.read(themeModeProvider.notifier).toggle();
    expect(next.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(ThemeModeNotifier.key), 'light');
  });

  test('system is never used; asking for it gives light', () async {
    final (c, prefs) = await _container({'display.theme': 'dark'});
    c.read(themeModeProvider.notifier).set(ThemeMode.system);
    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString(ThemeModeNotifier.key), 'light');
  });

  test('both themes keep the brand and switch brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.scaffoldBackgroundColor, const Color(0xFFFAF7F0));
    expect(AppTheme.dark.colorScheme.secondary, AppColors.gold);
  });

  testWidgets('settings toggle flips and persists the mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: ThemeModeRow()),
          ),
        ),
      ),
    );
    final toggle = find.byKey(const ValueKey('theme-mode-toggle'));
    expect(tester.widget<AppToggle>(toggle).on, isFalse);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<AppToggle>(toggle).on, isTrue);
    expect(prefs.getString(ThemeModeNotifier.key), 'dark');
  });
}
