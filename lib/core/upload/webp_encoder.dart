import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Encoded image bytes plus their display size (EXIF orientation applied).
class EncoderSource {
  const EncoderSource({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Seam over the native WebP encoder so the compression algorithm can be
/// tested with a deterministic fake.
abstract interface class WebpEncoder {
  /// Returns an upright WebP without metadata whose longest side is at most
  /// [maxLongEdge] (never upscaled), or `null` when encoding fails.
  Future<Uint8List?> encode(
    EncoderSource source, {
    required int quality,
    required int maxLongEdge,
  });
}

/// Box handed to `flutter_image_compress` so that the longest side ends up at
/// [maxLongEdge].
///
/// The plugin names these parameters `minWidth`/`minHeight` but scales by
/// `max(1, min(w / minWidth, h / minHeight))` (Android) and fits to the box
/// aspect (iOS), so a square box would bound the SHORT side instead. A box
/// with the source aspect ratio works identically on both platforms, and both
/// interpret it in the display frame (Android swaps it for 90/270 EXIF).
({int width, int height}) fitBox(int width, int height, int maxLongEdge) {
  final scale = math.max(1, math.max(width, height) / maxLongEdge);
  return (
    width: math.max(1, (width / scale).floor()),
    height: math.max(1, (height / scale).floor()),
  );
}

/// [WebpEncoder] backed by `flutter_image_compress` (system encoder on
/// Android, libwebp through SDWebImageWebPCoder on iOS). The plugin is
/// async-native, so nothing here blocks the UI isolate.
class NativeWebpEncoder implements WebpEncoder {
  const NativeWebpEncoder();

  @override
  Future<Uint8List?> encode(
    EncoderSource source, {
    required int quality,
    required int maxLongEdge,
  }) async {
    final box = fitBox(source.width, source.height, maxLongEdge);
    final out = await FlutterImageCompress.compressWithList(
      source.bytes,
      minWidth: box.width,
      minHeight: box.height,
      quality: quality,
      format: CompressFormat.webp,
    );
    return out.isEmpty ? null : out;
  }
}
