import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/image_compressor.dart';
import 'package:kawalo_mobile/core/upload/webp_encoder.dart';

typedef Call = ({int quality, int edge});

class FakeEncoder implements WebpEncoder {
  FakeEncoder(this.sizeOf, {this.returnNull = false});

  final int Function(int quality, int edge) sizeOf;
  final bool returnNull;
  final calls = <Call>[];

  @override
  Future<Uint8List?> encode(
    EncoderSource source, {
    required int quality,
    required int maxLongEdge,
  }) async {
    calls.add((quality: quality, edge: maxLongEdge));
    if (returnNull) return null;
    return Uint8List(sizeOf(quality, maxLongEdge));
  }
}

class _ThrowingEncoder implements WebpEncoder {
  @override
  Future<Uint8List?> encode(
    EncoderSource source, {
    required int quality,
    required int maxLongEdge,
  }) => throw StateError('native failure');
}

AppMediaFile photo() => AppMediaFile(name: 'a.jpg', bytes: Uint8List(8));

ImageCompressor compressorOf(
  FakeEncoder encoder, {
  int width = 4000,
  int height = 3000,
}) => ImageCompressor(
  encoder: encoder,
  readDimensions: (_) => (width: width, height: height),
);

int sizeOfRight(Either<Failure, Uint8List> either) =>
    either.getOrElse((_) => Uint8List(0)).length;

void main() {
  test('picks the highest quality that still fits at the first size', () async {
    // 5000 bytes per quality point: q93 = 148000 fits, q94 = 153000 does not.
    final encoder = FakeEncoder((q, _) => 5000 * (q - 90) + 133000);
    final result = await compressorOf(encoder).compress(photo());

    expect(sizeOfRight(result), 148000);
    expect(encoder.calls.every((c) => c.edge == 1600), isTrue);
    expect(encoder.calls.first.quality, 90);
  });

  test('never goes below quality 90 and shrinks dimensions stepwise', () async {
    // Only edges <= 1152 fit, whatever the quality.
    final encoder = FakeEncoder((q, edge) => edge <= 1152 ? 100000 : 200000);
    final result = await compressorOf(encoder).compress(photo());

    expect(result.isRight(), isTrue);
    expect(encoder.calls.every((c) => c.quality >= 90), isTrue);
    expect(encoder.calls.take(4).map((c) => c.edge), [1600, 1440, 1280, 1152]);
    expect(encoder.calls.where((c) => c.edge > 1152).length, 3);
    // 100000 fits at every quality, so the search ends at 100.
    expect(encoder.calls.last.edge, 1152);
    expect(
      encoder.calls.map((c) => c.quality).reduce((a, b) => a > b ? a : b),
      100,
    );
    expect(sizeOfRight(result), 100000);
  });

  test(
    'fails with an Indonesian message when even 640 px is too big',
    () async {
      final encoder = FakeEncoder((_, _) => 150000);
      final result = await compressorOf(encoder).compress(photo());

      result.match(
        (f) => expect(f.message, ImageCompressor.tooBigMessage),
        (_) => fail('expected failure'),
      );
      expect(encoder.calls.map((c) => c.edge).toList(), [
        1600,
        1440,
        1280,
        1152,
        1024,
        896,
        768,
        640,
      ]);
      expect(encoder.calls.every((c) => c.quality == 90), isTrue);
    },
  );

  test('150000 bytes is rejected, 149999 is accepted', () async {
    final at = FakeEncoder((_, _) => 150000);
    expect((await compressorOf(at).compress(photo())).isLeft(), isTrue);
    final below = FakeEncoder((_, _) => 149999);
    expect((await compressorOf(below).compress(photo())).isRight(), isTrue);
  });

  test(
    'does not try sizes above the source and never repeats a call',
    () async {
      final encoder = FakeEncoder((_, _) => 1000);
      await compressorOf(encoder, width: 1000, height: 800).compress(photo());

      expect(encoder.calls.map((c) => c.edge).toSet(), {1000});
      expect(encoder.calls.toSet().length, encoder.calls.length);
      // q90 plus a binary search over 91..100 is at most 5 native calls.
      expect(encoder.calls.length, lessThanOrEqualTo(5));
    },
  );

  test('stops at the first size whose quality 90 fits', () async {
    final encoder = FakeEncoder((q, edge) => edge == 1440 ? 140000 : 160000);
    await compressorOf(encoder).compress(photo());

    expect(encoder.calls.where((c) => c.edge == 1600).length, 1);
    expect(encoder.calls.any((c) => c.edge < 1440), isFalse);
  });

  test('passes a small WebP within 1600 px through without encoding', () async {
    final webp = Uint8List.fromList([
      ...'RIFF'.codeUnits,
      0,
      0,
      0,
      0,
      ...'WEBP'.codeUnits,
      0,
      0,
    ]);
    final encoder = FakeEncoder((_, _) => 1);
    final result = await compressorOf(
      encoder,
      width: 1200,
      height: 900,
    ).compress(AppMediaFile(name: 'a.webp', bytes: webp));

    expect(result.getOrElse((_) => Uint8List(0)), same(webp));
    expect(encoder.calls, isEmpty);
  });

  test('fails cleanly on unreadable input, null output and errors', () async {
    final unreadable = ImageCompressor(
      encoder: FakeEncoder((_, _) => 1),
      readDimensions: (_) => null,
    );
    expect((await unreadable.compress(photo())).isLeft(), isTrue);
    const missing = AppMediaFile(name: 'x.jpg', path: '/nope/x.jpg');
    expect((await unreadable.compress(missing)).isLeft(), isTrue);

    final nullEncoder = FakeEncoder((_, _) => 1, returnNull: true);
    expect(
      (await compressorOf(nullEncoder).compress(photo())).isLeft(),
      isTrue,
    );

    final throwing = ImageCompressor(
      encoder: _ThrowingEncoder(),
      readDimensions: (_) => (width: 100, height: 100),
    );
    (await throwing.compress(photo())).match(
      (f) => expect(f.message, ImageCompressor.encodeFailedMessage),
      (_) => fail('expected failure'),
    );
  });

  group('fitBox', () {
    test('bounds the LONG edge and keeps the aspect ratio', () {
      expect(fitBox(4000, 3000, 1600), (width: 1600, height: 1200));
      expect(fitBox(3000, 4000, 1600), (width: 1200, height: 1600));
      expect(fitBox(1000, 800, 1600), (width: 1000, height: 800));
    });
  });

  group('readDisplayDimensions', () {
    test('returns null for non-image bytes', () {
      expect(readDisplayDimensions(Uint8List.fromList([1, 2, 3])), isNull);
    });

    test('swaps width and height for EXIF orientation 6', () {
      final image = img.Image(width: 40, height: 20)
        ..exif.imageIfd.orientation = 6;
      final jpg = Uint8List.fromList(img.encodeJpg(image));

      expect(readDisplayDimensions(jpg), (width: 20, height: 40));
    });

    test('keeps dimensions without EXIF orientation', () {
      final jpg = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 40, height: 20)),
      );

      expect(readDisplayDimensions(jpg), (width: 40, height: 20));
    });
  });
}
