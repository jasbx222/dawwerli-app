import 'dart:io';

import 'package:dawwerli/core/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const keys = [
    'furniture', 'appliances', 'gaming', 'car-parts', 'kids', 'sports',
    'books', 'beauty', 'watches', 'perfumes', 'pharmacy', 'food', 'gifts',
    'pets', 'tools', 'phones', 'electronics', 'clothing', 'home',
    // Keys already in the catalog seed.
    'shoes', 'clothes', 'care',
  ];

  test('every category key maps to a bundled SVG', () {
    for (final k in keys) {
      final asset = categoryIconAsset(k);
      expect(asset, isNot(endsWith('/$categoryFallbackIcon.svg')), reason: k);
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('unknown, empty and null keys use the fallback icon', () {
    for (final k in ['unknown-thing', '', null]) {
      expect(categoryIconAsset(k), 'assets/icons/categories/category.svg');
    }
    expect(File(categoryIconAsset(null)).existsSync(), isTrue);
  });

  test('keys are matched case- and separator-insensitively', () {
    expect(categoryIconAsset('Car_Parts'), categoryIconAsset('car-parts'));
  });

  test('bundled SVGs use currentColor so they can be tinted', () {
    for (final f in Directory('assets/icons/categories').listSync()) {
      if (!f.path.endsWith('.svg')) continue;
      expect(File(f.path).readAsStringSync(), contains('currentColor'));
    }
  });

  testWidgets('CategoryIcon renders an SVG asset', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: CategoryIconTile('phones')),
      ),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
