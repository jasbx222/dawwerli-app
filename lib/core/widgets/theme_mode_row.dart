import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_mode.dart';
import 'app_icons.dart';
import 'app_toggle.dart';
import 'settings_row.dart';

/// «الوضع الليلي» switch for the customer and page settings. The app never
/// follows the device theme; this row is the only way to change it.
class ThemeModeRow extends ConsumerWidget {
  const ThemeModeRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    void toggle() => ref.read(themeModeProvider.notifier).setDark(!dark);
    return Semantics(
      toggled: dark,
      label: 'الوضع الليلي',
      child: SettingsRow(
        dark ? AppIcon.moon : AppIcon.sparkles,
        'الوضع الليلي',
        sub: dark ? 'مفعّل · ألوان داكنة' : 'مطفي · ألوان فاتحة',
        onTap: toggle,
        trailing: AppToggle(
          key: const ValueKey('theme-mode-toggle'),
          on: dark,
          onTap: toggle,
        ),
      ),
    );
  }
}
