// Loads the customer's wall photo for «حطها على حايطك». The photo only ever
// lives in memory on the device: nothing here (or anywhere in the preview)
// sends it to the API.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'wall_math.dart';

/// Longest edge kept in memory. Big enough for a sharp share image, small
/// enough that a 48 MP photo can't exhaust memory on older phones.
const wallPhotoMaxEdge = 2048;

/// Files above these limits are refused rather than decoded.
const wallPhotoMaxBytes = 40 * 1024 * 1024;
const wallPhotoMaxPixels = 80 * 1000 * 1000;

enum WallPickFailure {
  /// Camera / photos permission refused (iOS raises this; Android's system
  /// camera and photo picker need no runtime permission).
  denied,

  /// No camera on this device (simulators, some tablets).
  noCamera,

  /// Not an image we can decode.
  unreadable,
}

class WallPickException implements Exception {
  const WallPickException(this.failure);
  final WallPickFailure failure;
}

/// Opens the camera or the gallery. Returns null when the user cancels.
Future<ui.Image?> pickWallPhoto({
  required bool camera,
  ImagePicker? picker,
}) async {
  XFile? x;
  try {
    x = await (picker ?? ImagePicker()).pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      // The platform resizes (and bakes in the EXIF rotation on iOS) before
      // the bytes ever reach Dart.
      maxWidth: wallPhotoMaxEdge.toDouble(),
      maxHeight: wallPhotoMaxEdge.toDouble(),
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
  } on PlatformException catch (e) {
    final code = e.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission')) {
      throw const WallPickException(WallPickFailure.denied);
    }
    if (code.contains('no_available_camera') || code.contains('camera')) {
      throw const WallPickException(WallPickFailure.noCamera);
    }
    throw const WallPickException(WallPickFailure.unreadable);
  }
  if (x == null) return null;
  try {
    final bytes = await x.readAsBytes();
    return await decodeWallPhoto(bytes);
  } catch (_) {
    throw const WallPickException(WallPickFailure.unreadable);
  }
}

/// Decodes [bytes] upright and at most [maxEdge] px on its longest side.
Future<ui.Image> decodeWallPhoto(
  Uint8List bytes, {
  int maxEdge = wallPhotoMaxEdge,
}) async {
  if (bytes.isEmpty || bytes.length > wallPhotoMaxBytes) {
    throw const WallPickException(WallPickFailure.unreadable);
  }
  // Check the size before decoding, so a huge file can't exhaust memory.
  final buf = await ui.ImmutableBuffer.fromUint8List(bytes);
  final desc = await ui.ImageDescriptor.encoded(buf);
  final pixels = desc.width * desc.height;
  desc.dispose();
  buf.dispose();
  if (pixels <= 0 || pixels > wallPhotoMaxPixels) {
    throw const WallPickException(WallPickFailure.unreadable);
  }
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  var img = frame.image;
  // Flutter's decoders honour EXIF orientation on every platform we ship.
  // Safety net for one that doesn't: a 90° orientation whose decoded size
  // still equals the stored (unrotated) frame was not applied, so do it here.
  final info = JpegInfo.read(bytes);
  final o =
      info != null &&
          info.swapsAxes &&
          info.width != info.height &&
          img.width == info.width &&
          img.height == info.height
      ? info.orientation
      : 1;
  final k = math.min(1.0, maxEdge / math.max(img.width, img.height));
  if (o == 1 && k == 1) return img;
  final out = _redraw(img, o, k);
  img.dispose();
  return out;
}

/// Draws [src] rotated per EXIF [o] (1, 5–8) and scaled by [k].
ui.Image _redraw(ui.Image src, int o, double k) {
  final w = src.width * k, h = src.height * k;
  final swap = o >= 5;
  final ow = math.max(1, (swap ? h : w).round());
  final oh = math.max(1, (swap ? w : h).round());
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  if (o != 1) {
    final t = exifAffine(o, w, h);
    c.transform(
      Float64List.fromList([
        t.a, t.b, 0, 0, t.c, t.d, 0, 0, 0, 0, 1, 0, t.tx, t.ty, 0, 1, //
      ]),
    );
  }
  c.drawImageRect(
    src,
    ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
    ui.Rect.fromLTWH(0, 0, w, h),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final pic = rec.endRecording();
  final img = pic.toImageSync(ow, oh);
  pic.dispose();
  return img;
}

/// Whether this platform has a camera to open (web: pick a photo instead).
bool get wallCameraAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
