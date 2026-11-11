import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_recording_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_recording_model.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_recording_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements PttRecordingRemoteDataSource {}

void main() {
  late MockRemote remote;
  late Directory tmp;
  late PttRecordingRepositoryImpl repository;

  setUp(() {
    remote = MockRemote();
    tmp = Directory.systemTemp.createTempSync('ptt_repo_test');
    repository = PttRecordingRepositoryImpl(
      remoteDataSource: remote,
      temporaryDirectory: () async => tmp,
    );
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  void stubDownload() {
    when(() => remote.downloadAudio(any(), any())).thenAnswer((inv) async {
      File(inv.positionalArguments[1] as String).writeAsBytesSync([1, 2, 3]);
    });
  }

  group('getRecordings', () {
    test('passes the cursor and returns the mapped page', () async {
      when(
        () => remote.getRecordings(
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PttRecordingPageModel(items: [], nextBefore: 'n'),
      );

      final result = await repository.getRecordings(before: 'c', limit: 5);

      expect(result.getOrElse((_) => throw StateError('left')).nextBefore, 'n');
      verify(() => remote.getRecordings(before: 'c', limit: 5)).called(1);
    });

    test('maps an exception to a failure', () async {
      when(
        () => remote.getRecordings(
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(const NoInternetException());

      final result = await repository.getRecordings();

      expect(
        result.swap().getOrElse((_) => throw StateError('right')),
        isA<NoInternetFailure>(),
      );
    });
  });

  group('fetchAudio', () {
    test('downloads once and reuses the file afterwards', () async {
      stubDownload();

      final first = await repository.fetchAudio('rec_1');
      final second = await repository.fetchAudio('rec_1');

      final path = first.getOrElse((_) => throw StateError('left'));
      expect(path, endsWith('rec_1.ogg'));
      expect(File(path).existsSync(), isTrue);
      expect(second, first);
      verify(() => remote.downloadAudio('rec_1', any())).called(1);
      expect(File('$path.part').existsSync(), isFalse);
    });

    test(
      'a failed download leaves no playable file and returns a failure',
      () async {
        when(
          () => remote.downloadAudio(any(), any()),
        ).thenThrow(const ServerException('Rekaman tidak ditemukan.', 404));

        final result = await repository.fetchAudio('rec_1');

        expect(result.isLeft(), isTrue);
        expect(
          File('${tmp.path}/ptt_recordings/rec_1.ogg').existsSync(),
          isFalse,
        );
      },
    );

    test('clearAudioCache removes the downloaded files', () async {
      stubDownload();
      await repository.fetchAudio('rec_1');

      await repository.clearAudioCache();

      expect(Directory('${tmp.path}/ptt_recordings').existsSync(), isFalse);
    });
  });

  group('deleteRecording', () {
    test('deletes remotely and drops the cached file', () async {
      stubDownload();
      await repository.fetchAudio('rec_1');
      when(() => remote.deleteRecording('rec_1')).thenAnswer((_) async {});

      final result = await repository.deleteRecording('rec_1');

      expect(result.isRight(), isTrue);
      expect(
        File('${tmp.path}/ptt_recordings/rec_1.ogg').existsSync(),
        isFalse,
      );
    });

    test('a server refusal is a failure', () async {
      when(
        () => remote.deleteRecording(any()),
      ).thenThrow(const ServerException('Hanya administrator.', 403));

      final result = await repository.deleteRecording('rec_1');

      expect(result.isLeft(), isTrue);
    });
  });
}
