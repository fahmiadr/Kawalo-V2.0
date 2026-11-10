import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/image_compressor.dart';
import 'package:kawalo_mobile/core/upload/upload_remote_data_source.dart';
import 'package:kawalo_mobile/core/upload/upload_repository_impl.dart';
import 'package:kawalo_mobile/core/upload/webp_encoder.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements UploadRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class _SmallEncoder implements WebpEncoder {
  @override
  Future<Uint8List?> encode(
    EncoderSource source, {
    required int quality,
    required int maxLongEdge,
  }) async => Uint8List.fromList([1, 2, 3]);
}

void main() {
  late MockRemote remote;
  late MockNetworkInfo network;
  late UploadRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(UploadKind.image);
    registerFallbackValue(DioMediaType('a', 'b'));
  });

  setUp(() {
    remote = MockRemote();
    network = MockNetworkInfo();
    when(() => network.isConnected).thenAnswer((_) async => true);
    repository = UploadRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: network,
      compressor: ImageCompressor(
        encoder: _SmallEncoder(),
        readDimensions: (_) => (width: 4000, height: 3000),
      ),
    );
  });

  void stubUpload([Object? error]) {
    final call = when(
      () => remote.upload(
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        kind: any(named: 'kind'),
        contentType: any(named: 'contentType'),
        onProgress: any(named: 'onProgress'),
      ),
    );
    if (error != null) {
      call.thenThrow(error);
    } else {
      call.thenAnswer((_) async => 'https://cdn.kawalo.id/u/1');
    }
  }

  final photo = AppMediaFile(name: 'IMG_1.jpg', bytes: Uint8List(8));

  group('uploadImage', () {
    test(
      'uploads the compressed bytes as <uuid>.webp with image/webp',
      () async {
        stubUpload();

        final result = await repository.uploadImage(photo);

        expect(
          result,
          const Right<Failure, String>('https://cdn.kawalo.id/u/1'),
        );
        final captured = verify(
          () => remote.upload(
            bytes: captureAny(named: 'bytes'),
            filename: captureAny(named: 'filename'),
            kind: captureAny(named: 'kind'),
            contentType: captureAny(named: 'contentType'),
            onProgress: any(named: 'onProgress'),
          ),
        ).captured;
        expect(captured[0], Uint8List.fromList([1, 2, 3]));
        expect(captured[1], matches(RegExp(r'^[0-9a-f-]{36}\.webp$')));
        expect(captured[2], UploadKind.image);
        expect((captured[3] as DioMediaType).mimeType, 'image/webp');
      },
    );

    test('returns the compressor failure without calling the server', () async {
      final failing = UploadRepositoryImpl(
        remoteDataSource: remote,
        compressor: ImageCompressor(
          encoder: _SmallEncoder(),
          readDimensions: (_) => null,
        ),
      );

      final result = await failing.uploadImage(photo);

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => remote.upload(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          kind: any(named: 'kind'),
          contentType: any(named: 'contentType'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('is a NoInternetFailure when offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.uploadImage(photo);

      expect(result, const Left<Failure, String>(NoInternetFailure()));
    });

    test('maps server errors to failures', () async {
      stubUpload(const ServerException('Ukuran gambar melebihi 150 KB', 413));

      final result = await repository.uploadImage(photo);

      result.match((f) {
        expect(f, isA<ServerFailure>());
        expect(f.message, 'Ukuran gambar melebihi 150 KB');
        expect(f.statusCode, 413);
      }, (_) => fail('expected failure'));
    });

    test('maps network errors to the existing network failures', () async {
      stubUpload(const NoInternetException());

      final result = await repository.uploadImage(photo);

      expect(
        result.swap().getOrElse((_) => throw StateError('')),
        isA<NoInternetFailure>(),
      );
    });
  });

  group('uploadDocument', () {
    AppMediaFile doc(String name, {int size = 1000, String? ext}) =>
        AppMediaFile(
          name: name,
          bytes: Uint8List(size),
          sizeInBytes: size,
          extension: ext,
        );

    test('uploads an allowed document with its own extension', () async {
      stubUpload();

      final result = await repository.uploadDocument(
        doc('laporan.PDF', ext: 'pdf'),
      );

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => remote.upload(
          bytes: any(named: 'bytes'),
          filename: captureAny(named: 'filename'),
          kind: captureAny(named: 'kind'),
          contentType: captureAny(named: 'contentType'),
          onProgress: any(named: 'onProgress'),
        ),
      ).captured;
      expect(captured[0], endsWith('.pdf'));
      expect(captured[1], UploadKind.document);
      expect((captured[2] as DioMediaType).mimeType, 'application/pdf');
    });

    test('derives the extension from the name when none is given', () async {
      stubUpload();

      expect(
        (await repository.uploadDocument(doc('data.xlsx'))).isRight(),
        isTrue,
      );
    });

    test('rejects extensions outside the allowlist', () async {
      for (final name in ['virus.exe', 'foto.jpg', 'noext']) {
        final result = await repository.uploadDocument(doc(name));
        result.match(
          (f) => expect(
            f.message,
            UploadRepositoryImpl.unsupportedDocumentMessage,
          ),
          (_) => fail('expected failure for $name'),
        );
      }
      verifyNever(
        () => remote.upload(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          kind: any(named: 'kind'),
          contentType: any(named: 'contentType'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('rejects documents above 10 MB, accepts exactly 10 MB', () async {
      stubUpload();
      const limit = UploadRepositoryImpl.maxDocumentBytes;

      final tooBig = await repository.uploadDocument(
        doc('a.pdf', size: limit + 1),
      );
      tooBig.match(
        (f) => expect(f.message, UploadRepositoryImpl.documentTooLargeMessage),
        (_) => fail('expected failure'),
      );
      expect(
        (await repository.uploadDocument(doc('a.pdf', size: limit))).isRight(),
        isTrue,
      );
    });

    test('fails when the file cannot be read', () async {
      const missing = AppMediaFile(name: 'a.pdf', path: '/nope/a.pdf');

      final result = await repository.uploadDocument(missing);

      result.match(
        (f) =>
            expect(f.message, UploadRepositoryImpl.unreadableDocumentMessage),
        (_) => fail('expected failure'),
      );
    });
  });
}
