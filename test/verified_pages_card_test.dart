import 'dart:async';

import 'package:dawwerli/core/l10n/app_strings.dart';
import 'package:dawwerli/core/storage/prefs.dart';
import 'package:dawwerli/core/theme/app_colors.dart';
import 'package:dawwerli/features/home/data/home_providers.dart';
import 'package:dawwerli/features/home/domain/home_models.dart';
import 'package:dawwerli/features/home/domain/home_repository.dart';
import 'package:dawwerli/features/home/presentation/widgets/verified_pages_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpyRepo implements HomeRepository {
  final calls = <String?>[];
  @override
  Future<HomeData> load({String? governorate}) {
    calls.add(governorate);
    return Completer<HomeData>().future; // never needed
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<Widget> _card({
  int count = 1234,
  int? govs = 18,
  VoidCallback? onTap,
}) async => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: VerifiedPagesCard(
        count: count,
        pages: const [],
        governorates: govs,
        onTap: onTap ?? () {},
      ),
    ),
  ),
);

void main() {
  tearDown(() => AppColors.dark = false);

  group('Arabic plurals', () {
    test('verified pages label', () {
      expect(AppStrings.verifiedPagesLabel(1), 'صفحة موثّقة');
      expect(AppStrings.verifiedPagesLabel(2), 'صفحتين موثّقتين');
      expect(AppStrings.verifiedPagesLabel(3), 'صفحات موثّقة');
      expect(AppStrings.verifiedPagesLabel(10), 'صفحات موثّقة');
      expect(AppStrings.verifiedPagesLabel(11), 'صفحة موثّقة');
      expect(AppStrings.verifiedPagesLabel(59), 'صفحة موثّقة');
      expect(AppStrings.verifiedPagesLabel(103), 'صفحات موثّقة');
    });

    test('governorates', () {
      expect(AppStrings.inGovernorates(1), 'بمحافظة وحدة');
      expect(AppStrings.inGovernorates(2), 'بمحافظتين');
      expect(AppStrings.inGovernorates(5), 'بـ5 محافظات');
      expect(AppStrings.inGovernorates(18), 'بـ18 محافظة');
    });
  });

  group('home headline', () {
    test('uses the customer governorate', () {
      expect(
        AppStrings.homeHeadline('البصرة', allIraq: false),
        'كول، والبصرة تتسابق عليك',
      );
    });
    test('guest or no governorate → all Iraq', () {
      expect(
        AppStrings.homeHeadline('بغداد', allIraq: true),
        AppStrings.homeQ2All,
      );
      expect(AppStrings.homeHeadline('', allIraq: false), AppStrings.homeQ2All);
    });
  });

  group('home governorate request', () {
    Future<_SpyRepo> run(Map<String, Object> stored) async {
      SharedPreferences.setMockInitialValues(stored);
      final prefs = await SharedPreferences.getInstance();
      final spy = _SpyRepo();
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          homeRepositoryProvider.overrideWithValue(spy),
        ],
      );
      addTearDown(c.dispose);
      c.read(homeDataProvider);
      await Future<void>.delayed(Duration.zero);
      return spy;
    }

    test(
      'no saved region → let the server use the profile governorate',
      () async {
        final spy = await run({});
        expect(spy.calls, [null]);
      },
    );

    test('a region picked on the device is sent', () async {
      final spy = await run({'region.gov': 'نينوى', 'region.area': 'الزهور'});
      expect(spy.calls, ['نينوى']);
    });
  });

  group('VerifiedPagesCard', () {
    testWidgets('shows the real count with separators and plural label', (
      t,
    ) async {
      await t.pumpWidget(await _card());
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('صفحة موثّقة'), findsOneWidget);
      expect(find.textContaining('بـ18 محافظة'), findsOneWidget);
      expect(find.text('+1,234'), findsOneWidget);
    });

    testWidgets('card and «شوفها» both open the pages', (t) async {
      var taps = 0;
      await t.pumpWidget(await _card(onTap: () => taps++));
      await t.tap(find.text(AppStrings.verifiedSeeThem));
      await t.pumpAndSettle();
      await t.tap(find.text('1,234'));
      await t.pumpAndSettle();
      expect(taps, 2);
    });

    testWidgets('renders in dark mode', (t) async {
      AppColors.dark = true;
      await t.pumpWidget(await _card(count: 5, govs: null));
      expect(find.text('صفحات موثّقة'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
