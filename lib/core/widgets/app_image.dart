import 'dart:io';

import 'package:flutter/material.dart';

/// Image from an API URL, a local file (camera) or a bundled asset.
ImageProvider appImage(String ref) {
  // `blob:` is a picked photo on web.
  if (ref.startsWith('http') || ref.startsWith('blob:')) {
    return NetworkImage(ref);
  }
  if (ref.startsWith('/')) return FileImage(File(ref));
  return AssetImage(ref);
}

/// Drop-in for `Image.asset` that also accepts URLs and file paths.
class AppImage extends StatelessWidget {
  const AppImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return SizedBox(width: width, height: height);
    return Image(
      image: appImage(source),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
    );
  }
}
