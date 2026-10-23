import 'package:dawwerli/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    final theme = AppTheme.build(dark: dark);
    final mode = dark ? 'dark' : 'light';

    test('$mode: borderless fields stay borderless in every state', () {
      final t = theme.inputDecorationTheme;
      for (final d in [
        const InputDecoration.collapsed(hintText: ''),
        const InputDecoration(border: InputBorder.none, isCollapsed: true),
      ]) {
        final r = d.applyDefaults(t);
        expect(r.border, InputBorder.none);
        expect(r.enabledBorder, isNull);
        expect(r.focusedBorder, isNull);
        expect(r.errorBorder, isNull);
        expect(r.disabledBorder, isNull);
      }
    });

    test('$mode: plain fields get one rounded outline from the theme', () {
      final r = const InputDecoration(hintText: 'x')
          .applyDefaults(theme.inputDecorationTheme);
      expect(r.border, isA<OutlineInputBorder>());
    });
  }
}
