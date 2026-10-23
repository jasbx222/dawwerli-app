import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:dawwerli/features/store/data/store_data.dart';
import 'package:dawwerli/features/wall/wall_math.dart';
import 'package:flutter_test/flutter_test.dart';

double _gap(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void near(Offset a, Offset b, [double tol = 1e-6]) {
  expect((a - b).distance, lessThan(tol), reason: '$a vs $b');
}

/// Pinhole camera looking at a wall (z = 0, units cm) from an angle.
/// Returns a function wall(x, y) -> pixel.
Offset Function(Offset) camera({
  double yawDeg = 25,
  double pitchDeg = -10,
  double dist = 250,
  double f = 1400,
  Offset principal = const Offset(1000, 750),
}) {
  final yaw = yawDeg * math.pi / 180, pitch = pitchDeg * math.pi / 180;
  return (Offset w) {
    // Wall point relative to the camera, then rotate yaw (y-axis) and pitch.
    var x = w.dx - 15, y = w.dy - 20, z = dist;
    final x1 = x * math.cos(yaw) + z * math.sin(yaw);
    final z1 = -x * math.sin(yaw) + z * math.cos(yaw);
    x = x1;
    z = z1;
    final y2 = y * math.cos(pitch) - z * math.sin(pitch);
    final z2 = y * math.sin(pitch) + z * math.cos(pitch);
    return Offset(principal.dx + f * x / z2, principal.dy + f * y2 / z2);
  };
}

void main() {
  group('Homography', () {
    test('maps the four known points exactly and inverts', () {
      final src = a4Corners(landscape: false);
      const dst = [
        Offset(120, 80),
        Offset(410, 95),
        Offset(400, 520),
        Offset(105, 500),
      ];
      final h = Homography.tryFromPoints(src, dst)!;
      for (var i = 0; i < 4; i++) {
        near(h.map(src[i]), dst[i], 1e-6);
      }
      final inv = h.inverse()!;
      for (final p in [const Offset(3, 7), const Offset(10.5, 14.85)]) {
        near(inv.map(h.map(p)), p, 1e-6);
      }
    });

    test('identity and pure scale', () {
      const sq = [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)];
      const big = [Offset(0, 0), Offset(10, 0), Offset(10, 10), Offset(0, 10)];
      final h = Homography.tryFromPoints(sq, big)!;
      near(h.map(const Offset(.5, .25)), const Offset(5, 2.5));
    });

    test('degenerate points give null, not garbage', () {
      const line = [Offset(0, 0), Offset(1, 1), Offset(2, 2), Offset(3, 3)];
      expect(
        Homography.tryFromPoints(a4Corners(landscape: false), line),
        isNull,
      );
    });

    test('real size within 1% under a perspective view', () {
      final cam = camera();
      final a4 = a4Corners(landscape: false);
      final quad = [for (final c in a4) cam(c)];
      final h = wallToPhoto(quad, landscape: false)!;
      final inv = h.inverse()!;
      // A 145 × 83 cm TV placed next to the sheet: project its corners with
      // the true camera, then measure them back through the fitted mapping.
      const tl = Offset(-40, -30);
      const s = WallSize(145, 83, WallKind.tv);
      final truth = [for (final c in productCorners(tl, s)) cam(c)];
      final fitted = [for (final c in productCorners(tl, s)) h.map(c)];
      for (var i = 0; i < 4; i++) {
        near(fitted[i], truth[i], 1e-3);
      }
      final back = [for (final p in truth) inv.map(p)];
      final w = (back[1] - back[0]).distance;
      final hh = (back[3] - back[0]).distance;
      expect((w - 145).abs() / 145, lessThan(.01));
      expect((hh - 83).abs() / 83, lessThan(.01));
    });

    test('1% holds with a half-pixel corner error', () {
      final cam = camera(yawDeg: 15, pitchDeg: 0, dist: 300, f: 1600);
      final a4 = a4Corners(landscape: false);
      final quad = [for (final c in a4) cam(c)];
      // Nudge one corner by a typical tap error.
      quad[1] = quad[1] + const Offset(0.5, 0.5);
      final h = wallToPhoto(quad, landscape: false)!;
      final inv = h.inverse()!;
      const s = WallSize(60, 40, WallKind.frame);
      final truth = [for (final c in productCorners(Offset.zero, s)) cam(c)];
      final back = [for (final p in truth) inv.map(p)];
      final w = (back[1] - back[0]).distance;
      expect((w - 60).abs() / 60, lessThan(.01));
    });
  });

  group('corners', () {
    test('orderCorners sorts any order to TL, TR, BR, BL', () {
      const q = [
        Offset(10, 10),
        Offset(100, 12),
        Offset(98, 150),
        Offset(8, 140),
      ];
      for (final perm in [
        [2, 0, 3, 1],
        [3, 2, 1, 0],
        [1, 3, 0, 2],
      ]) {
        final o = orderCorners([for (final i in perm) q[i]]);
        for (var i = 0; i < 4; i++) {
          near(o[i], q[i]);
        }
      }
    });

    test('validateQuad accepts a fair sheet and rejects bad ones', () {
      const photo = Size(2000, 1500);
      expect(validateQuad(defaultQuad(photo), photo), isNull);
      // Tiny.
      expect(
        validateQuad(const [
          Offset(10, 10),
          Offset(20, 10),
          Offset(20, 24),
          Offset(10, 24),
        ], photo),
        QuadIssue.tooSmall,
      );
      // Crossed (bow-tie).
      expect(
        validateQuad(const [
          Offset(100, 100),
          Offset(600, 900),
          Offset(600, 100),
          Offset(100, 900),
        ], photo),
        QuadIssue.notConvex,
      );
      // Concave (one corner pushed inward).
      expect(
        validateQuad(const [
          Offset(100, 100),
          Offset(600, 100),
          Offset(300, 300),
          Offset(100, 900),
        ], photo),
        QuadIssue.notConvex,
      );
      // Very sheared.
      expect(
        validateQuad(const [
          Offset(100, 100),
          Offset(400, 100),
          Offset(1400, 400),
          Offset(1100, 400),
        ], photo),
        QuadIssue.tooSkewed,
      );
    });

    test('landscape detection follows the drawn shape', () {
      const wide = [
        Offset(0, 0),
        Offset(300, 0),
        Offset(300, 200),
        Offset(0, 200),
      ];
      expect(quadLooksLandscape(wide), isTrue);
      expect(quadLooksLandscape(defaultQuad(const Size(1000, 1000))), isFalse);
    });

    test('clampPlacement keeps the whole product on the photo', () {
      const photo = Size(1000, 1000);
      final h = wallToPhoto(defaultQuad(photo), landscape: false)!;
      const s = WallSize(30, 30, WallKind.frame);
      const start = Offset(0, 0);
      expect(placementOk(h, start, s, photo), isTrue);
      // A far drag stops with the right edge flush on the photo's edge.
      final far = clampPlacement(h, start, const Offset(5000, 0), s, photo);
      expect(far.dy, 0);
      expect(h.map(far + const Offset(30, 0)).dx, closeTo(1000, .5));
      expect(placementOk(h, far, s, photo), isTrue);
      // …and still slides along it.
      final slide = clampPlacement(h, start, const Offset(5000, 5), s, photo);
      expect(slide.dy, 5);
      expect(h.map(slide + const Offset(30, 0)).dx, closeTo(1000, .5));
      final ok = clampPlacement(h, start, const Offset(3, 4), s, photo);
      expect(ok, const Offset(3, 4));
    });

    test('the centre on the photo is not enough: edges count', () {
      const photo = Size(1000, 1000);
      final h = wallToPhoto(defaultQuad(photo), landscape: false)!;
      const s = WallSize(60, 30, WallKind.tv);
      // Centre well inside the photo, right edge past it.
      final tl =
          h.inverse()!.map(const Offset(900, 500)) - const Offset(30, 15);
      expect(placementOk(h, tl, s, photo), isFalse);
      expect(placementOverflow(h, tl, s, photo), greaterThan(0));
    });

    test('a product bigger than the photo must keep covering it', () {
      const photo = Size(1000, 1000);
      final h = wallToPhoto(defaultQuad(photo), landscape: false)!;
      const s = WallSize(200, 200, WallKind.tv);
      final start =
          h.inverse()!.map(const Offset(500, 500)) - const Offset(100, 100);
      expect(placementOk(h, start, s, photo), isTrue);
      final moved = clampPlacement(
        h,
        start,
        start + const Offset(500, 0),
        s,
        photo,
      );
      expect(h.map(moved).dx, closeTo(0, .5));
      expect(placementOk(h, moved, s, photo), isTrue);
    });

    test('orientation warning only when the photo clearly disagrees', () {
      const wide = [
        Offset(0, 0),
        Offset(297, 0),
        Offset(297, 210),
        Offset(0, 210),
      ];
      const square = [
        Offset(0, 0),
        Offset(100, 0),
        Offset(100, 105),
        Offset(0, 105),
      ];
      expect(orientationContradicts(wide, landscape: false), isTrue);
      expect(orientationContradicts(wide, landscape: true), isFalse);
      final tall = defaultQuad(const Size(1000, 1000));
      expect(orientationContradicts(tall, landscape: true), isTrue);
      expect(orientationContradicts(tall, landscape: false), isFalse);
      expect(orientationContradicts(square, landscape: true), isFalse);
      expect(orientationContradicts(square, landscape: false), isFalse);
    });

    test('corner order keeps its labels near 45° roll (hysteresis)', () {
      List<Offset> rolled(double deg) {
        final a = deg * math.pi / 180;
        Offset r(Offset p) => Offset(
          500 + p.dx * math.cos(a) - p.dy * math.sin(a),
          500 + p.dx * math.sin(a) + p.dy * math.cos(a),
        );
        return [
          for (final p in const [
            Offset(-150, -105),
            Offset(150, -105),
            Offset(150, 105),
            Offset(-150, 105),
          ])
            r(p),
        ];
      }

      // Plain ordering flips somewhere around 45°.
      final plain = topEdgeDeg(orderCorners(rolled(50)));
      expect(_gap(plain, 50), greaterThan(30));
      // Coming from 40°, the labels carry on to 50°…
      final kept = orderCornersStable(rolled(50), prevTopDeg: 40);
      expect(topEdgeDeg(kept), closeTo(50, 1e-6));
      expect(quadLooksLandscape(kept), isTrue);
      // …and only give up past 45° + 10°.
      final gone = orderCornersStable(rolled(60), prevTopDeg: 50);
      expect(_gap(topEdgeDeg(gone), 60), greaterThan(30));
      // Without history it is the plain order.
      expect(orderCornersStable(rolled(50)), orderCorners(rolled(50)));
    });

    test('accuracy: a big sheet is precise, a tiny one approximate', () {
      const photo = Size(4000, 3000);
      const s = WallSize(145, 83, WallKind.tv);
      final big = defaultQuad(photo);
      final good = wallAccuracy(
        big,
        photo,
        s,
        centredOnSheet(s, landscape: false),
        landscape: false,
      );
      expect(good.approximate, isFalse, reason: '${good.sizeErrorPct}');
      expect(good.tilted, isFalse);
      expect(good.tilt, closeTo(1, 1e-6));

      final c = big.fold(Offset.zero, (a, p) => a + p) / 4;
      final tiny = [for (final p in big) c + (p - c) * .25];
      final bad = wallAccuracy(
        tiny,
        photo,
        s,
        centredOnSheet(s, landscape: false),
        landscape: false,
      );
      expect(bad.approximate, isTrue);
      expect(bad.sizeErrorPct, greaterThan(good.sizeErrorPct));
    });

    test('accuracy: a steep angle reads as tilted', () {
      final cam = camera(yawDeg: 55, pitchDeg: 0, dist: 200);
      final quad = [for (final p in a4Corners(landscape: false)) cam(p)];
      const s = WallSize(145, 83, WallKind.tv);
      final a = wallAccuracy(
        quad,
        const Size(2000, 1500),
        s,
        centredOnSheet(s, landscape: false),
        landscape: false,
      );
      expect(a.tilted, isTrue, reason: '${a.tilt}');
      final flat = camera(yawDeg: 0, pitchDeg: 0);
      final q2 = [for (final p in a4Corners(landscape: false)) flat(p)];
      final b = wallAccuracy(
        q2,
        const Size(2000, 1500),
        s,
        centredOnSheet(s, landscape: false),
        landscape: false,
      );
      expect(b.tilted, isFalse, reason: '${b.tilt}');
    });

    test('centredOnSheet centres the product on the A4', () {
      const s = WallSize(10, 4, WallKind.frame);
      final p = centredOnSheet(s, landscape: true);
      near(p + const Offset(5, 2), const Offset(a4LongCm / 2, a4ShortCm / 2));
    });
  });

  group('visibility rule', () {
    test('needs width, height and a known kind', () {
      expect(
        WallSize.of(widthCm: 100, heightCm: 60, wallKind: 'tv'),
        isNotNull,
      );
      expect(WallSize.of(widthCm: 100, heightCm: null, wallKind: 'tv'), isNull);
      expect(WallSize.of(widthCm: null, heightCm: 60, wallKind: 'tv'), isNull);
      expect(WallSize.of(widthCm: 100, heightCm: 60, wallKind: null), isNull);
      expect(WallSize.of(widthCm: 100, heightCm: 60, wallKind: 'sofa'), isNull);
      expect(WallSize.of(widthCm: 0, heightCm: 60, wallKind: 'tv'), isNull);
      expect(WallSize.of(widthCm: 2000, heightCm: 60, wallKind: 'tv'), isNull);
      expect(
        WallSize.of(widthCm: double.nan, heightCm: 60, wallKind: 'tv'),
        isNull,
      );
    });

    test('round mirror only when square', () {
      expect(
        WallSize.of(widthCm: 60, heightCm: 60, wallKind: 'mirror')!.round,
        isTrue,
      );
      expect(
        WallSize.of(widthCm: 60, heightCm: 90, wallKind: 'mirror')!.round,
        isFalse,
      );
      expect(
        WallSize.of(widthCm: 60, heightCm: 60, wallKind: 'frame')!.round,
        isFalse,
      );
    });

    test('StoreProduct parses sizes and variants defensively', () {
      final p = StoreProduct.fromJson({
        'id': 'a',
        'name': 'شاشة 65',
        'price': 900000,
        'stock': 2,
        'widthCm': 145,
        'heightCm': 83.4,
        'depthCm': -3,
        'wallKind': 'tv',
        'variantLabel': '65 إنش',
        'variants': [
          {
            'id': 'b',
            'label': '',
            'name': 'شاشة 55',
            'price': 700000,
            'stock': 0,
            'widthCm': 123,
            'heightCm': 71,
            'wallKind': 'tv',
          },
          {
            'id': 'a',
            'label': '65 إنش',
            'name': 'شاشة 65',
            'price': 900000,
            'stock': 2,
            'widthCm': 145,
            'heightCm': 83.4,
            'wallKind': 'tv',
          },
          'junk',
        ],
      });
      expect(p.wall!.widthCm, 145);
      expect(p.depthCm, isNull);
      expect(p.hasSize, isTrue);
      expect(p.variants, hasLength(2));
      expect(p.variants.first.label, 'شاشة 55');
      expect(p.variants.first.available, isFalse);
      expect(p.variants.last.wall!.heightCm, 83.4);
      expect(sizeText(p.wall!), contains('145'));

      final plain = StoreProduct.fromJson({
        'id': 'c',
        'name': 'x',
        'widthCm': '145',
        'heightCm': 80,
        'wallKind': 'tv',
        'variants': 'nope',
      });
      expect(plain.wall, isNull);
      expect(plain.variants, isEmpty);
    });
  });

  group('JPEG / EXIF', () {
    Uint8List jpeg({
      int? orientation,
      bool little = false,
      int w = 40,
      int h = 30,
    }) {
      final out = <int>[0xFF, 0xD8];
      if (orientation != null) {
        int b16(int v) => v;
        final tiff = <int>[
          ...(little ? [0x49, 0x49, 0x2A, 0x00] : [0x4D, 0x4D, 0x00, 0x2A]),
          ...(little ? [8, 0, 0, 0] : [0, 0, 0, 8]),
          ...(little ? [1, 0] : [0, 1]),
          ...(little ? [0x12, 0x01, 3, 0] : [0x01, 0x12, 0, 3]),
          ...(little ? [1, 0, 0, 0] : [0, 0, 0, 1]),
          ...(little
              ? [b16(orientation), 0, 0, 0]
              : [0, b16(orientation), 0, 0]),
          0,
          0,
          0,
          0,
        ];
        final body = [0x45, 0x78, 0x69, 0x66, 0, 0, ...tiff];
        final len = body.length + 2;
        out.addAll([0xFF, 0xE1, len >> 8, len & 0xFF, ...body]);
      }
      out.addAll([
        0xFF,
        0xC0,
        0,
        11,
        8,
        h >> 8,
        h & 0xFF,
        w >> 8,
        w & 0xFF,
        1,
        1,
        0x11,
        0,
      ]);
      out.addAll([0xFF, 0xD9]);
      return Uint8List.fromList(out);
    }

    test('reads orientation (both byte orders) and frame size', () {
      final a = JpegInfo.read(jpeg(orientation: 6))!;
      expect(a.orientation, 6);
      expect(a.swapsAxes, isTrue);
      expect((a.width, a.height), (40, 30));
      final b = JpegInfo.read(jpeg(orientation: 8, little: true))!;
      expect(b.orientation, 8);
      final c = JpegInfo.read(jpeg())!;
      expect(c.orientation, 1);
      expect(c.swapsAxes, isFalse);
    });

    test('never throws on junk', () {
      expect(JpegInfo.read(Uint8List(0)), isNull);
      expect(
        JpegInfo.read(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])),
        isNull,
      );
      final cut = jpeg(orientation: 6);
      for (var n = 0; n < cut.length; n++) {
        JpegInfo.read(Uint8List.sublistView(cut, 0, n));
      }
      final rnd = math.Random(7);
      for (var k = 0; k < 200; k++) {
        final b = Uint8List.fromList([
          0xFF,
          0xD8,
          for (var i = 0; i < 64; i++) rnd.nextInt(256),
        ]);
        JpegInfo.read(b);
      }
    });

    test('exifAffine turns the stored frame upright', () {
      Offset ap(int o, Offset p) {
        final t = exifAffine(o, 40, 30);
        return Offset(
          t.a * p.dx + t.c * p.dy + t.tx,
          t.b * p.dx + t.d * p.dy + t.ty,
        );
      }

      // 6 = rotate 90° clockwise: stored top-left lands top-right of a 30 × 40 image.
      near(ap(6, Offset.zero), const Offset(30, 0));
      near(ap(6, const Offset(40, 30)), const Offset(0, 40));
      // 8 = rotate 90° counter-clockwise.
      near(ap(8, Offset.zero), const Offset(0, 40));
      near(ap(8, const Offset(40, 30)), const Offset(30, 0));
      // 1 = identity.
      near(ap(1, const Offset(3, 4)), const Offset(3, 4));
      // Every orientation keeps the frame inside its upright box.
      for (var o = 1; o <= 8; o++) {
        final sw = o >= 5;
        final bw = sw ? 30.0 : 40.0, bh = sw ? 40.0 : 30.0;
        for (final c in const [
          Offset(0, 0),
          Offset(40, 0),
          Offset(40, 30),
          Offset(0, 30),
        ]) {
          final p = ap(o, c);
          expect(p.dx, inInclusiveRange(-1e-9, bw + 1e-9), reason: 'o=$o');
          expect(p.dy, inInclusiveRange(-1e-9, bh + 1e-9), reason: 'o=$o');
        }
      }
    });
  });

  group('imageHeaderSize', () {
    test('reads PNG, GIF and WebP headers', () {
      final png = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
        0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52, //
        0, 0, 0x04, 0x4C, 0, 0, 0x05, 0xBB, 8, 2, 0, 0, 0,
      ]);
      expect(imageHeaderSize(png), (1100, 1467));
      final gif = Uint8List.fromList([
        0x47,
        0x49,
        0x46,
        0x38,
        0x39,
        0x61,
        0x40,
        0x01,
        0xF0,
        0x00,
        0,
        0,
      ]);
      expect(imageHeaderSize(gif), (320, 240));
      final webp = Uint8List(30)
        ..setAll(0, 'RIFF'.codeUnits)
        ..setAll(8, 'WEBPVP8X'.codeUnits)
        ..setAll(24, [0x3F, 0x01, 0x00, 0xEF, 0x00, 0x00]);
      expect(imageHeaderSize(webp), (320, 240));
    });

    test('never throws and rejects junk or zero sizes', () {
      final rnd = math.Random(7);
      for (var n = 0; n < 200; n++) {
        final b = Uint8List.fromList(
          List.generate(rnd.nextInt(40), (_) => rnd.nextInt(256)),
        );
        expect(() => imageHeaderSize(b), returnsNormally);
      }
      expect(imageHeaderSize(Uint8List(0)), isNull);
      final zero = Uint8List.fromList([
        0x47,
        0x49,
        0x46,
        0x38,
        0x39,
        0x61,
        0,
        0,
        0,
        0,
      ]);
      expect(imageHeaderSize(zero), isNull);
      final truncatedPng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0]);
      expect(imageHeaderSize(truncatedPng), isNull);
    });
  });

  test('size picker never mixes wall kinds', () {
    final p = StoreProduct.fromJson({
      'id': 'a',
      'name': 'شاشة 55',
      'widthCm': 123,
      'heightCm': 71,
      'wallKind': 'tv',
      'variants': [
        {
          'id': 'a',
          'label': '55',
          'widthCm': 123,
          'heightCm': 71,
          'wallKind': 'tv',
        },
        {
          'id': 'b',
          'label': '65',
          'widthCm': 145,
          'heightCm': 83,
          'wallKind': 'TV',
        },
        {
          'id': 'c',
          'label': 'مراية',
          'widthCm': 60,
          'heightCm': 90,
          'wallKind': 'mirror',
        },
      ],
    });
    expect(p.sizeChoices.map((v) => v.id), ['a', 'b']);
  });
}
