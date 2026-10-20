import 'dart:io';

import 'package:flutter/services.dart';

import 'api_client.dart';

/// Uploads a local image (camera/gallery file or bundled asset) and returns its storage key.
/// Already-uploaded URLs return null (nothing to send).
Future<String?> uploadImage(ApiClient api, String? source, String kind) async {
  if (source == null || source.isEmpty || source.startsWith('http')) return null;
  final bytes = source.startsWith('/')
      ? await File(source).readAsBytes()
      : (await rootBundle.load(source)).buffer.asUint8List();
  return api.upload(bytes, source.split('/').last, kind);
}
