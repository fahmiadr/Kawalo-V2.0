import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/webp_encoder.dart';

/// Reads the display size (EXIF orientation applied) from the image header.
typedef ImageDimensionsReader =
    ({int width, int height})? Function(Uint8List bytes);

/// Default [ImageDimensionsReader]: parses only headers, no pixel decoding.
({int width, int height})? readDisplayDimensions(Uint8List bytes) {
  final info = img.findDecoderForData(bytes)?.startDecode(bytes);
  if (info == null || info.width <= 0 || info.height <= 0) return null;
  final orientation = img.decodeJpgExif(bytes)?.imageIfd.orientation ?? 1;
  final swap = orientation >= 5 && orientation <= 8;
  return swap
      ? (width: info.height, height: info.width)
      : (width: info.width, height: info.height);
}

/// Compresses any picked image to WebP at quality 90 to 100 and strictly
/// under [maxBytes].
///
/// For each long-edge step (largest first) the cheapest quality (90) is tried
/// first; the first step that fits wins, and only then is the quality raised
/// by binary search over 91..100 to get the largest result that still fits.
/// Quality never drops below [minQuality]; only the dimensions shrink.
class ImageCompressor {
  const ImageCompressor({
    WebpEncoder encoder = const NativeWebpEncoder(),
    ImageDimensionsReader readDimensions = readDisplayDimensions,
  }) : _encoder = encoder,
       _readDimensions = readDimensions;

  /// Hard server limit: results must be strictly smaller than this.
  static const int maxBytes = 150000;
  static const int minQuality = 90;
  static const int maxQuality = 100;
  static const List<int> longEdgeSteps = [
    1600,
    1440,
    1280,
    1152,
    1024,
    896,
    768,
    640,
  ];

  static const String tooBigMessage =
      'Foto tidak dapat dikecilkan hingga di bawah 150 KB. '
      'Gunakan foto lain.';
  static const String unreadableMessage =
      'Berkas foto tidak dapat dibaca. Pilih foto lain.';
  static const String encodeFailedMessage =
      'Foto gagal diproses. Silakan coba lagi.';

  final WebpEncoder _encoder;
  final ImageDimensionsReader _readDimensions;

  Future<Either<Failure, Uint8List>> compress(AppMediaFile file) async {
    try {
      final bytes = file.bytes ?? await _readFile(file.path);
      final size = bytes == null ? null : _readDimensions(bytes);
      if (bytes == null || size == null) {
        return const Left(ValidationFailure(unreadableMessage));
      }

      final longEdge = max(size.width, size.height);
      if (bytes.length < maxBytes &&
          longEdge <= longEdgeSteps.first &&
          _isWebp(bytes)) {
        return Right(bytes);
      }

      final source = EncoderSource(
        bytes: bytes,
        width: size.width,
        height: size.height,
      );
      // Steps above the source size collapse into one "original size" attempt.
      final edges = {for (final e in longEdgeSteps) min(e, longEdge)};
      for (final edge in edges) {
        final first = await _encoder.encode(
          source,
          quality: minQuality,
          maxLongEdge: edge,
        );
        if (first == null) {
          return const Left(ValidationFailure(encodeFailedMessage));
        }
        if (first.length >= maxBytes) continue;

        var best = first;

        var low = minQuality + 1;
        var high = maxQuality;
        while (low <= high) {
          final mid = (low + high) ~/ 2;
          final out = await _encoder.encode(
            source,
            quality: mid,
            maxLongEdge: edge,
          );
          if (out != null && out.length < maxBytes) {
            best = out;
            low = mid + 1;
          } else {
            high = mid - 1;
          }
        }
        return Right(best);
      }
      return const Left(ValidationFailure(tooBigMessage));
    } on Object catch (_) {
      return const Left(ValidationFailure(encodeFailedMessage));
    }
  }

  static Future<Uint8List?> _readFile(String? path) async {
    if (path == null) return null;
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  static bool _isWebp(Uint8List b) =>
      b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP';
}
