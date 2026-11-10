import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/upload/upload_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class SeenRequest {
  SeenRequest(this.options, this.body);

  final RequestOptions options;
  final String body;
}

/// Replies with queued responses and records every multipart body.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.replies);

  final List<ResponseBody Function()> replies;
  final seen = <SeenRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await requestStream.forEach(chunks.addAll);
    }
    seen.add(SeenRequest(options, latin1.decode(chunks)));
    return replies[(seen.length - 1).clamp(0, replies.length - 1)]();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Map<String, dynamic> json, int status) =>
    ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

ResponseBody ok() => jsonBody({
  'success': true,
  'message': 'ok',
  'data': {'url': 'https://cdn.kawalo.id/u/1.webp', 'kind': 'image'},
}, 201);

void main() {
  late MockApiClient apiClient;
  late FakeAdapter adapter;
  late UploadRemoteDataSource dataSource;

  void setUpAdapter(List<ResponseBody Function()> replies) {
    adapter = FakeAdapter(replies);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'))
      ..httpClientAdapter = adapter;
    when(() => apiClient.dio).thenReturn(dio);
    dataSource = UploadRemoteDataSource(apiClient: apiClient);
  }

  Future<String> upload({
    UploadKind kind = UploadKind.image,
    void Function(double)? onProgress,
  }) => dataSource.upload(
    bytes: Uint8List.fromList(List.filled(1000, 7)),
    filename: 'abc.webp',
    kind: kind,
    contentType: DioMediaType('image', 'webp'),
    onProgress: onProgress,
  );

  setUp(() {
    apiClient = MockApiClient();
    when(() => apiClient.onConnectionFailed).thenReturn(null);
  });

  test(
    'sends multipart file and kind to /v1/uploads and parses data.url',
    () async {
      setUpAdapter([ok]);

      final url = await upload();

      expect(url, 'https://cdn.kawalo.id/u/1.webp');
      final req = adapter.seen.single;
      expect(req.options.method, 'POST');
      expect(req.options.uri.path, '/api/v1/uploads');
      expect(
        req.options.headers['content-type'] as String,
        startsWith('multipart/form-data; boundary='),
      );
      expect(req.body, matches(RegExp(r'name="kind"\r\n\r\nimage\r\n')));
      expect(req.body, contains('name="file"; filename="abc.webp"'));
      expect(req.body.toLowerCase(), contains('content-type: image/webp'));
    },
  );

  test('reports progress as fractions within 0..1', () async {
    setUpAdapter([ok]);
    final fractions = <double>[];

    await upload(onProgress: fractions.add);

    expect(fractions, isNotEmpty);
    expect(fractions.every((f) => f >= 0 && f <= 1), isTrue);
    expect(fractions.last, 1.0);
  });

  test('maps 413 to the size message per kind', () async {
    setUpAdapter([
      () => jsonBody({'success': false, 'message': 'x'}, 413),
    ]);
    await expectLater(
      upload(),
      throwsA(
        isA<ServerException>()
            .having(
              (e) => e.message,
              'message',
              'Ukuran gambar melebihi 150 KB',
            )
            .having((e) => e.statusCode, 'status', 413),
      ),
    );

    setUpAdapter([
      () => jsonBody({'success': false, 'message': 'x'}, 413),
    ]);
    await expectLater(
      upload(kind: UploadKind.document),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Ukuran dokumen melebihi 10 MB',
        ),
      ),
    );
  });

  test('maps 422 to the server message', () async {
    setUpAdapter([
      () => jsonBody({
        'success': false,
        'message': 'Gambar harus berformat WebP',
        'error_code': 'VALIDATION_ERROR',
      }, 422),
    ]);

    await expectLater(
      upload(),
      throwsA(
        isA<ServerException>()
            .having((e) => e.message, 'message', 'Gambar harus berformat WebP')
            .having((e) => e.statusCode, 'status', 422),
      ),
    );
  });

  test('rejects a 2xx response without data.url', () async {
    setUpAdapter([
      () => jsonBody({'success': true, 'data': <String, dynamic>{}}, 201),
    ]);

    await expectLater(upload(), throwsA(isA<ServerException>()));
  });

  test('retries once with a fresh FormData after a 401', () async {
    setUpAdapter([
      () => jsonBody({'success': false, 'message': 'expired'}, 401),
      ok,
    ]);

    final url = await upload();

    expect(url, 'https://cdn.kawalo.id/u/1.webp');
    expect(adapter.seen, hasLength(2));
    expect(adapter.seen.last.body, contains('name="file"'));
  });

  test('gives up after a second 401', () async {
    setUpAdapter([
      () => jsonBody({'success': false, 'message': 'expired'}, 401),
    ]);

    await expectLater(upload(), throwsA(isA<AuthException>()));
    expect(adapter.seen, hasLength(2));
  });

  test('newUuid returns a v4 uuid', () {
    expect(
      UploadRemoteDataSource.newUuid(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
