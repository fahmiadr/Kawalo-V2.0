import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance/photo/authenticated_photo_fetcher.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);

  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromBytes(
      [1, 2, 3],
      status,
      headers: {
        Headers.contentTypeHeader: ['image/jpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('photo_fetcher'));
  tearDown(() => temp.deleteSync(recursive: true));

  AuthenticatedPhotoFetcher build(_Adapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'))
      ..httpClientAdapter = adapter;
    // The auth interceptor is not under test here, only the download.
    final apiClient = MockApiClient();
    when(() => apiClient.dio).thenReturn(dio);
    return AuthenticatedPhotoFetcher(
      apiClient: apiClient,
      temporaryDirectory: () async => temp,
    );
  }

  test('downloads into a file and discard removes it', () async {
    final adapter = _Adapter(200);
    final fetcher = build(adapter);

    final path = (await fetcher.fetch(
      '/v1/attendance/9/photo',
      name: 'attendance/9',
    )).toNullable();

    expect(path, isNotNull);
    expect(File(path!).readAsBytesSync(), [1, 2, 3]);
    expect(adapter.last?.path, '/v1/attendance/9/photo');
    expect(path, isNot(contains('attendance/9')));

    await fetcher.discard(path);
    expect(File(path).existsSync(), isFalse);
  });

  test('a 403 becomes a failure', () async {
    final result = await build(_Adapter(403)).fetch('/x', name: 'x');

    expect(result.isLeft(), isTrue);
  });
}
