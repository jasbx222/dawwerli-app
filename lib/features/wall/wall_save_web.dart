import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'wall_save.dart';

Future<WallSaveResult> saveWallImage(
  Uint8List png, {
  required String name,
}) async {
  try {
    final blob = web.Blob(
      [png.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = '$name.png'
      ..style.display = 'none';
    web.document.body?.append(a);
    a.click();
    a.remove();
    // Give the browser a moment to start the download before revoking.
    Future<void>.delayed(
      const Duration(seconds: 2),
      () => web.URL.revokeObjectURL(url),
    );
    return WallSaveResult.downloaded;
  } catch (_) {
    return WallSaveResult.failed;
  }
}
