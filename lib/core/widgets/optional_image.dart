import 'package:flutter/material.dart';

/// Shows an asset image if it exists, otherwise [fallback].
///
/// Uses the standard asset pipeline so a bundled image always loads. A missing
/// asset shows [fallback] (Flutter logs a single 404 per missing path, which
/// disappears once the file is added and the app is fully restarted).
class OptionalImage extends StatelessWidget {
  const OptionalImage({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String path;
  final BoxFit fit;
  final Widget fallback;

  /// Downsample large images at decode time to save GPU memory.
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
