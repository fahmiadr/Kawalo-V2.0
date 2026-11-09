import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/file_download_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/file_download_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  Future<Directory> docs() async => Directory('/docs');

  void stubDownload(Future<Response<dynamic>> Function(Invocation) answer) {
    when(
      () => dio.download(
        any(),
        any<dynamic>(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
      ),
    ).thenAnswer(answer);
  }

  Response<dynamic> ok() => Response<dynamic>(requestOptions: RequestOptions());

  setUp(() {
    dio = _MockDio();
  });

  blocTest<FileDownloadCubit, FileDownloadState>(
    'network file reports progress then done and saves under documents dir',
    build: () {
      stubDownload((invocation) async {
        final onProgress =
            invocation.namedArguments[#onReceiveProgress] as ProgressCallback;
        onProgress(50, 100);
        onProgress(10, -1);
        return ok();
      });
      return FileDownloadCubit(dio, documentsDirectory: docs);
    },
    act: (cubit) => cubit.download('https://x.id/f/sop.pdf?t=1'),
    expect: () => const [
      FileDownloadInProgress(0.1),
      FileDownloadInProgress(0.5),
      FileDownloadDone(),
    ],
    verify: (_) {
      verify(
        () => dio.download(
          'https://x.id/f/sop.pdf?t=1',
          '/docs/sop.pdf',
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).called(1);
    },
  );

  blocTest<FileDownloadCubit, FileDownloadState>(
    'network error emits failure with Indonesian message',
    build: () {
      when(
        () => dio.download(
          any(),
          any<dynamic>(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(Exception('boom'));
      return FileDownloadCubit(dio, documentsDirectory: docs);
    },
    act: (cubit) => cubit.download('https://x.id/sop.pdf'),
    expect: () => [
      const FileDownloadInProgress(0.1),
      isA<FileDownloadFailure>().having(
        (s) => s.message,
        'message',
        startsWith('Gagal mengunduh berkas: '),
      ),
    ],
  );

  blocTest<FileDownloadCubit, FileDownloadState>(
    'local file simulates five progress steps without touching Dio',
    build: () => FileDownloadCubit(dio, documentsDirectory: docs),
    act: (cubit) => cubit.download('sop.pdf'),
    wait: const Duration(milliseconds: 800),
    expect: () => const [
      FileDownloadInProgress(0.1),
      FileDownloadInProgress(0.2),
      FileDownloadInProgress(0.4),
      FileDownloadInProgress(0.6),
      FileDownloadInProgress(0.8),
      FileDownloadInProgress(1),
      FileDownloadDone(),
    ],
    verify: (_) => verifyZeroInteractions(dio),
  );

  blocTest<FileDownloadCubit, FileDownloadState>(
    'falls back to /downloads when documents dir is unavailable',
    build: () {
      stubDownload((_) async => ok());
      return FileDownloadCubit(
        dio,
        documentsDirectory: () async => throw Exception('no dir'),
      );
    },
    act: (cubit) => cubit.download('https://x.id/a.zip'),
    verify: (_) {
      verify(
        () => dio.download(
          any(),
          '/downloads/a.zip',
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).called(1);
    },
  );

  test('ignores a second download while one is in progress', () async {
    final cubit = FileDownloadCubit(dio, documentsDirectory: docs);
    final first = cubit.download('sop.pdf');
    await cubit.download('sop.pdf');
    expect(cubit.state, const FileDownloadInProgress(0.1));
    await first;
    expect(cubit.state, const FileDownloadDone());
    await cubit.close();
  });
}
