import 'package:image_picker/image_picker.dart';

/// Max edge/quality for uploaded photos (keeps uploads small on mobile data).
abstract final class PhotoSpec {
  static const maxEdge = 1600.0;
  static const quality = 82;
}

/// Opens the camera (or gallery) and returns the local file path, or null if cancelled.
Future<String?> pickPhoto({bool camera = true}) async {
  final x = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: PhotoSpec.maxEdge,
    maxHeight: PhotoSpec.maxEdge,
    imageQuality: PhotoSpec.quality,
  );
  return x?.path;
}
