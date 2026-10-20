import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/settings/display_settings.dart';
import 'core/storage/prefs.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    // Native plugin mismatch on a stale Android build must not block startup:
    // fall back to in-memory prefs so the app still opens.
    debugPrint('SharedPreferences init failed, using in-memory fallback: $e');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  }
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const DawwerliApp(),
    ),
  );
}

class DawwerliApp extends ConsumerWidget {
  const DawwerliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(displaySettingsProvider);
    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    AppColors.dark =
        display.night == NightMode.on ||
        (display.night == NightMode.auto && systemDark);
    return MaterialApp.router(
      builder: (context, child) => RebuildOnChange(
        token: (AppColors.dark, display.font),
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(display.font.scale)),
          child: child!,
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'دوّرلي',
      theme: AppTheme.light,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [Locale('ar', 'IQ')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: appRouter,
      // Mouse/trackpad drag scrolls too (web + desktop), not just touch.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
    );
  }
}
