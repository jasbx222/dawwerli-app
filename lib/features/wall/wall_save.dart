// «حفظ بالصور»: saves the composited wall image. On phones it goes to the
// photo gallery (gal); on the web the browser downloads it as a PNG.
import 'dart:typed_data';

import 'wall_save_io.dart'
    if (dart.library.js_interop) 'wall_save_web.dart'
    as impl;

enum WallSaveResult { saved, downloaded, denied, failed }

/// Saves [png] as [name] (without extension).
Future<WallSaveResult> saveWallImage(Uint8List png, {required String name}) =>
    impl.saveWallImage(png, name: name);
