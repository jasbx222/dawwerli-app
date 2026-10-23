import 'dart:typed_data';

import 'package:gal/gal.dart';

import 'wall_save.dart';

Future<WallSaveResult> saveWallImage(
  Uint8List png, {
  required String name,
}) async {
  try {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      return WallSaveResult.denied;
    }
    await Gal.putImageBytes(png, name: name);
    return WallSaveResult.saved;
  } on GalException catch (e) {
    return e.type == GalExceptionType.accessDenied
        ? WallSaveResult.denied
        : WallSaveResult.failed;
  } catch (_) {
    return WallSaveResult.failed;
  }
}
