// «حطها على حايطك»: the geometry behind the real-size wall preview.
//
// The customer tapes an A4 sheet (21 × 29.7 cm) on the wall, photographs it
// and drags four handles onto its corners. Those four point pairs give a
// homography from wall centimetres to photo pixels, so a product of known
// width × height can be drawn on the photo at its true size. Pure Dart, no
// widgets, so every rule here is unit tested.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Size;

/// ISO A4, in centimetres.
const a4ShortCm = 21.0;
const a4LongCm = 29.7;

/// Size bounds the API accepts (Store:WallPreview), in centimetres.
const wallMinCm = 1.0;
const wallMaxCm = 1000.0;

/// What a wall product is; decides how the preview draws it.
enum WallKind {
  tv('شاشة'),
  mirror('مراية'),
  frame('إطار'),
  art('لوحة'),
  rug('سجادة جدارية'),
  shelf('رف'),
  clock('ساعة حائط'),
  other('القطعة');

  const WallKind(this.label);

  /// Short Arabic noun used in hints («اسحب الشاشة …»).
  final String label;

  /// API code (lowercase enum name) → kind; null for unknown/absent codes, so
  /// a kind added server-side later simply hides the button on old builds.
  static WallKind? parse(String? code) {
    if (code == null) return null;
    final c = code.trim().toLowerCase();
    for (final k in values) {
      if (k.name == c) return k;
    }
    return null;
  }
}

/// A product's wall footprint. Depth is informational only (never drawn).
class WallSize {
  const WallSize(this.widthCm, this.heightCm, this.kind, {this.depthCm});
  final double widthCm;
  final double heightCm;
  final double? depthCm;
  final WallKind kind;

  /// A mirror whose width equals its height is drawn round.
  bool get round => kind == WallKind.mirror && (widthCm - heightCm).abs() < .05;

  /// The visibility rule: the preview button shows only when width, height
  /// and a known wall kind are all set and the size is within API bounds.
  static WallSize? of({
    required double? widthCm,
    required double? heightCm,
    required String? wallKind,
    double? depthCm,
  }) {
    final kind = WallKind.parse(wallKind);
    if (kind == null || !validCm(widthCm) || !validCm(heightCm)) return null;
    return WallSize(
      widthCm!,
      heightCm!,
      kind,
      depthCm: validCm(depthCm) ? depthCm : null,
    );
  }

  static bool validCm(double? v) =>
      v != null && v.isFinite && v >= wallMinCm && v <= wallMaxCm;
}

/// `145` / `96.3`: centimetres the way the seller typed them.
String cmText(double v) {
  final r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
}

/// «145 × 83 سم» (plus depth when known and asked for).
String sizeText(WallSize s, {bool depth = false}) {
  final d = depth && s.depthCm != null ? ' × ${cmText(s.depthCm!)}' : '';
  return '${cmText(s.widthCm)} × ${cmText(s.heightCm)}$d سم';
}

/// 3×3 projective transform, row-major, h33 normalised to 1.
class Homography {
  const Homography(this.m);
  final List<double> m;

  /// Solves the 8 unknowns from 4 point pairs (DLT, partial pivoting).
  /// Returns null when the points are degenerate (three collinear, repeated).
  static Homography? tryFromPoints(List<Offset> src, List<Offset> dst) {
    assert(src.length == 4 && dst.length == 4);
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = src[i].dx, y = src[i].dy, u = dst[i].dx, v = dst[i].dy;
      a[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
      a[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
    }
    // Scale-aware singularity threshold.
    var mag = 0.0;
    for (final r in a) {
      for (final v in r) {
        mag = math.max(mag, v.abs());
      }
    }
    final eps = 1e-12 * math.max(1, mag);
    for (var c = 0; c < 8; c++) {
      var piv = c;
      for (var r = c + 1; r < 8; r++) {
        if (a[r][c].abs() > a[piv][c].abs()) piv = r;
      }
      if (a[piv][c].abs() <= eps) return null;
      final t = a[c];
      a[c] = a[piv];
      a[piv] = t;
      for (var r = 0; r < 8; r++) {
        if (r == c) continue;
        final f = a[r][c] / a[c][c];
        if (f == 0) continue;
        for (var k = c; k < 9; k++) {
          a[r][k] -= f * a[c][k];
        }
      }
    }
    final m = [for (var i = 0; i < 8; i++) a[i][8] / a[i][i], 1.0];
    if (m.any((v) => !v.isFinite)) return null;
    return Homography(m);
  }

  /// Projective weight of [p]; ≤ 0 means the point is at/behind the horizon.
  double weight(Offset p) => m[6] * p.dx + m[7] * p.dy + m[8];

  Offset map(Offset p) {
    final w = weight(p);
    return Offset(
      (m[0] * p.dx + m[1] * p.dy + m[2]) / w,
      (m[3] * p.dx + m[4] * p.dy + m[5]) / w,
    );
  }

  Homography? inverse() {
    final a = m[0], b = m[1], c = m[2];
    final d = m[3], e = m[4], f = m[5];
    final g = m[6], h = m[7], i = m[8];
    final co00 = e * i - f * h, co01 = c * h - b * i, co02 = b * f - c * e;
    final co10 = f * g - d * i, co11 = a * i - c * g, co12 = c * d - a * f;
    final co20 = d * h - e * g, co21 = b * g - a * h, co22 = a * e - b * d;
    final det = a * co00 + b * co10 + c * co20;
    if (!det.isFinite || det.abs() < 1e-15) return null;
    final s = 1 / det;
    return Homography([
      co00 * s, co01 * s, co02 * s, //
      co10 * s, co11 * s, co12 * s, //
      co20 * s, co21 * s, co22 * s,
    ]);
  }

  /// Column-major 4×4 for `Transform` (z passes through untouched).
  List<double> toMatrix4Storage() => [
    m[0], m[3], 0, m[6], //
    m[1], m[4], 0, m[7], //
    0, 0, 1, 0, //
    m[2], m[5], 0, m[8],
  ];
}

/// A4 corners in wall cm, clockwise from top-left, for the sheet as hung.
List<Offset> a4Corners({required bool landscape}) {
  final w = landscape ? a4LongCm : a4ShortCm;
  final h = landscape ? a4ShortCm : a4LongCm;
  return [Offset.zero, Offset(w, 0), Offset(w, h), Offset(0, h)];
}

/// Orders 4 points clockwise on screen (y down), starting at the top-left one,
/// so handles dragged past each other still describe the same sheet.
List<Offset> orderCorners(List<Offset> pts) {
  assert(pts.length == 4);
  final c = pts.fold(Offset.zero, (s, p) => s + p) / 4;
  final sorted = [...pts]
    ..sort(
      (p, q) => math
          .atan2(p.dy - c.dy, p.dx - c.dx)
          .compareTo(math.atan2(q.dy - c.dy, q.dx - c.dx)),
    );
  var start = 0;
  for (var i = 1; i < 4; i++) {
    final s = sorted[i], b = sorted[start];
    if (s.dx + s.dy < b.dx + b.dy) start = i;
  }
  return [for (var i = 0; i < 4; i++) sorted[(start + i) % 4]];
}

/// Why a corner quad can't be used (null = fine).
enum QuadIssue {
  tooSmall(
    'الورقة صغيرة كلش بالصورة. قرّب الزوايا من زوايا الورقة أو صوّر من أقرب.',
  ),
  notConvex('الزوايا متداخلة. خلّي كل دائرة على زاوية وحدة من الورقة.'),
  tooSkewed('الشكل مايل هواية. صوّر وانت مقابل الحايط، أو صلّح مكان الزوايا.');

  const QuadIssue(this.message);
  final String message;
}

double _cross(Offset o, Offset a, Offset b) =>
    (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

/// Signed shoelace area (positive = clockwise on a y-down screen).
double quadArea(List<Offset> q) {
  var s = 0.0;
  for (var i = 0; i < q.length; i++) {
    final a = q[i], b = q[(i + 1) % q.length];
    s += a.dx * b.dy - b.dx * a.dy;
  }
  return s / 2;
}

/// Checks the ordered sheet quad (TL, TR, BR, BL) in photo pixels: it must be
/// convex, big enough to measure from, and not so skewed that the homography
/// would blow small handle errors up into large size errors.
QuadIssue? validateQuad(List<Offset> q, Size photo) {
  assert(q.length == 4);
  final edge = math.max(photo.width, photo.height);
  final minSide = math.max(8.0, edge * .02);
  for (var i = 0; i < 4; i++) {
    if ((q[(i + 1) % 4] - q[i]).distance < minSide) return QuadIssue.tooSmall;
  }
  // Every turn the same way = convex, no three points collinear.
  final turns = [
    for (var i = 0; i < 4; i++) _cross(q[i], q[(i + 1) % 4], q[(i + 2) % 4]),
  ];
  final pos = turns.every((t) => t > 0), neg = turns.every((t) => t < 0);
  if (!pos && !neg) return QuadIssue.notConvex;
  if (quadArea(q).abs() < photo.width * photo.height * .001) {
    return QuadIssue.tooSmall;
  }
  for (var i = 0; i < 4; i++) {
    final p = q[i], a = q[(i + 3) % 4], b = q[(i + 1) % 4];
    final u = a - p, v = b - p;
    final cos = (u.dx * v.dx + u.dy * v.dy) / (u.distance * v.distance);
    final deg = math.acos(cos.clamp(-1.0, 1.0)) * 180 / math.pi;
    if (deg < 35 || deg > 145) return QuadIssue.tooSkewed;
  }
  double len(int i) => (q[(i + 1) % 4] - q[i]).distance;
  final r1 = len(0) / len(2), r2 = len(1) / len(3);
  if (r1 > 3 || r1 < 1 / 3 || r2 > 3 || r2 < 1 / 3) return QuadIssue.tooSkewed;
  return null;
}

/// Whether the sheet in the photo looks wider than tall (hung landscape).
bool quadLooksLandscape(List<Offset> q) {
  final w = (q[1] - q[0]).distance + (q[2] - q[3]).distance;
  final h = (q[3] - q[0]).distance + (q[2] - q[1]).distance;
  return w > h;
}

/// Wall cm → photo px for an ordered sheet quad, or null if unusable.
Homography? wallToPhoto(List<Offset> quad, {required bool landscape}) =>
    Homography.tryFromPoints(a4Corners(landscape: landscape), quad);

/// The product's 4 corners on the wall (cm), clockwise from top-left.
List<Offset> productCorners(Offset topLeft, WallSize s) => [
  topLeft,
  topLeft + Offset(s.widthCm, 0),
  topLeft + Offset(s.widthCm, s.heightCm),
  topLeft + Offset(0, s.heightCm),
];

/// Whether the product at [topLeft] can be drawn: all corners in front of
/// the camera and its centre inside the photo.
bool placementOk(Homography h, Offset topLeft, WallSize s, Size photo) {
  for (final c in productCorners(topLeft, s)) {
    if (h.weight(c) <= 1e-9) return false;
  }
  final mid = h.map(topLeft + Offset(s.widthCm / 2, s.heightCm / 2));
  return mid.dx >= 0 &&
      mid.dy >= 0 &&
      mid.dx <= photo.width &&
      mid.dy <= photo.height;
}

/// Applies a drag: [next] if valid, else slides along whichever axis still
/// is, else stays at [prev]. Keeps the product on the photo while dragging.
Offset clampPlacement(
  Homography h,
  Offset prev,
  Offset next,
  WallSize s,
  Size photo,
) {
  if (placementOk(h, next, s, photo)) return next;
  final xOnly = Offset(next.dx, prev.dy);
  if (placementOk(h, xOnly, s, photo)) return xOnly;
  final yOnly = Offset(prev.dx, next.dy);
  if (placementOk(h, yOnly, s, photo)) return yOnly;
  return prev;
}

/// Starting spot: product centred on the sheet's centre.
Offset centredOnSheet(WallSize s, {required bool landscape}) {
  final w = landscape ? a4LongCm : a4ShortCm;
  final h = landscape ? a4ShortCm : a4LongCm;
  return Offset(w / 2 - s.widthCm / 2, h / 2 - s.heightCm / 2);
}

/// Starting handles: an A4-shaped box in the middle of the photo.
List<Offset> defaultQuad(Size photo) {
  final h = photo.height * .28;
  final w = h * a4ShortCm / a4LongCm;
  final c = Offset(photo.width / 2, photo.height / 2);
  return [
    c + Offset(-w / 2, -h / 2),
    c + Offset(w / 2, -h / 2),
    c + Offset(w / 2, h / 2),
    c + Offset(-w / 2, h / 2),
  ];
}

/// JPEG facts read straight from the bytes: EXIF orientation (1–8, 1 when
/// absent) and the stored frame size before any rotation.
class JpegInfo {
  const JpegInfo(this.orientation, this.width, this.height);
  final int orientation;
  final int width;
  final int height;

  /// Orientations 5–8 rotate by 90°, swapping width and height.
  bool get swapsAxes => orientation >= 5 && orientation <= 8;

  /// Null for non-JPEG or malformed data. Never throws.
  static JpegInfo? read(Uint8List b) {
    try {
      return _read(b);
    } catch (_) {
      return null;
    }
  }

  static JpegInfo? _read(Uint8List b) {
    if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
    var orientation = 1;
    var i = 2;
    while (i + 4 <= b.length) {
      if (b[i] != 0xFF) return null;
      final marker = b[i + 1];
      if (marker == 0xFF) {
        i++;
        continue;
      }
      if (marker == 0xD9 || marker == 0xDA) break;
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2 || i + 2 + len > b.length) return null;
      final seg = i + 4;
      if (marker == 0xE1 && len >= 8) {
        orientation = _exifOrientation(b, seg, i + 2 + len) ?? orientation;
      }
      final sof =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (sof && len >= 7) {
        final h = (b[seg + 1] << 8) | b[seg + 2];
        final w = (b[seg + 3] << 8) | b[seg + 4];
        return JpegInfo(orientation.clamp(1, 8), w, h);
      }
      i += 2 + len;
    }
    return null;
  }

  static int? _exifOrientation(Uint8List b, int s, int end) {
    // "Exif\0\0" then a TIFF header.
    if (s + 14 > end ||
        b[s] != 0x45 ||
        b[s + 1] != 0x78 ||
        b[s + 2] != 0x69 ||
        b[s + 3] != 0x66) {
      return null;
    }
    final t = s + 6;
    final little = b[t] == 0x49 && b[t + 1] == 0x49;
    if (!little && !(b[t] == 0x4D && b[t + 1] == 0x4D)) return null;
    int u16(int o) => little ? b[o] | (b[o + 1] << 8) : (b[o] << 8) | b[o + 1];
    int u32(int o) => little
        ? b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)
        : (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
    final ifd = t + u32(t + 4);
    if (ifd + 2 > end) return null;
    final n = u16(ifd);
    for (var k = 0; k < n; k++) {
      final e = ifd + 2 + k * 12;
      if (e + 12 > end) return null;
      if (u16(e) == 0x0112) {
        final v = u16(e + 8);
        return v >= 1 && v <= 8 ? v : null;
      }
    }
    return null;
  }
}

/// Affine map (x' = a·x + c·y + tx, y' = b·x + d·y + ty) that turns a stored
/// w × h frame upright for EXIF orientation [o]. Mirror-only orientations
/// (2–4) map to identity: decoders that skip EXIF skip those too rarely to
/// matter, and the size check that detects a skipped rotation can't see them.
({double a, double b, double c, double d, double tx, double ty}) exifAffine(
  int o,
  double w,
  double h,
) => switch (o) {
  5 => (a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0), // transpose
  6 => (a: 0, b: 1, c: -1, d: 0, tx: h, ty: 0), // 90° clockwise
  7 => (a: 0, b: -1, c: -1, d: 0, tx: h, ty: w), // transverse
  8 => (a: 0, b: -1, c: 1, d: 0, tx: 0, ty: w), // 90° counter-clockwise
  _ => (a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0),
};

/// Width and height from a JPEG, PNG, GIF or WebP header, without decoding.
/// Null for anything else or malformed data. Never throws.
(int, int)? imageHeaderSize(Uint8List b) {
  try {
    final j = JpegInfo.read(b);
    if (j != null) {
      return j.width > 0 && j.height > 0 ? (j.width, j.height) : null;
    }
    int be32(int i) =>
        (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    int le16(int i) => b[i] | (b[i + 1] << 8);
    int le24(int i) => b[i] | (b[i + 1] << 8) | (b[i + 2] << 16);
    (int, int)? ok(int w, int h) => w > 0 && h > 0 ? (w, h) : null;
    // PNG: signature, then IHDR.
    if (b.length >= 24 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[12] == 0x49 &&
        b[13] == 0x48 &&
        b[14] == 0x44 &&
        b[15] == 0x52) {
      return ok(be32(16), be32(20));
    }
    // GIF87a / GIF89a logical screen.
    if (b.length >= 10 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) {
      return ok(le16(6), le16(8));
    }
    // WebP: RIFF....WEBP then VP8 / VP8L / VP8X.
    if (b.length >= 30 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      final c = String.fromCharCodes(b.sublist(12, 16));
      if (c == 'VP8 ') return ok(le16(26) & 0x3FFF, le16(28) & 0x3FFF);
      if (c == 'VP8L') {
        final v = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
        return ok((v & 0x3FFF) + 1, ((v >> 14) & 0x3FFF) + 1);
      }
      if (c == 'VP8X') return ok(le24(24) + 1, le24(27) + 1);
    }
    return null;
  } catch (_) {
    return null;
  }
}
