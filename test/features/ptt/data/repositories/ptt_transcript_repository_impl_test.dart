import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_transcript_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_transcript_fakes.dart';

class MockRemote extends Mock implements PttTranscriptRemoteDataSource {}

const ok = PttTranscript(
  requestId: 'req_1',
  status: PttTranscriptStatus.ok,
  text: 'Pos dua aman',
  locale: 'id-ID',
  reason: 'on_device_segmented_end',
);

void main() {
  late MockRemote remote;
  late FakeTranscriptLocalDataSource local;
  late DateTime now;
  late PttTranscriptRepositoryImpl repository;

  setUp(() {
    remote = MockRemote();
    local = FakeTranscriptLocalDataSource();
    now = DateTime(2026, 11, 11, 10);
    repository = PttTranscriptRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      now: () => now,
    );
  });

  void stubPut(Future<void> Function() answer) {
    when(
      () => remote.putTranscript(
        requestId: any(named: 'requestId'),
        status: any(named: 'status'),
        text: any(named: 'text'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) => answer());
  }

  test('uploads ok with text and locale, then removes the entry', () async {
    stubPut(() async {});
    await repository.enqueue(ok);

    expect(await repository.flush(), isNull);

    verify(
      () => remote.putTranscript(
        requestId: 'req_1',
        status: 'ok',
        text: 'Pos dua aman',
        locale: 'id-ID',
      ),
    ).called(1);
    expect(local.entries, isEmpty);
  });

  for (final status in [
    PttTranscriptStatus.failed,
    PttTranscriptStatus.unsupported,
  ]) {
    test('uploads ${status.name} without text', () async {
      stubPut(() async {});
      await repository.enqueue(
        PttTranscript(requestId: 'req_2', status: status, reason: 'x'),
      );

      await repository.flush();

      verify(
        () => remote.putTranscript(requestId: 'req_2', status: status.name),
      ).called(1);
      expect(local.entries, isEmpty);
    });
  }

  test('404 backs off 2 s, 4 s, 8 s, 15 s, and drops after 2 min', () async {
    stubPut(
      () async => throw const ServerException('Rekaman tidak ditemukan.', 404),
    );
    await repository.enqueue(ok);

    final waits = <Duration?>[];
    for (var i = 0; i < 4; i++) {
      final wait = await repository.flush();
      waits.add(wait);
      now = now.add(wait!);
    }
    expect(waits, const [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
    ]);
    expect(await repository.flush(), const Duration(seconds: 15));
    expect(local.entries['req_1']!.attempts, 5);

    // Past the window the turn was never recorded (e.g. no frames).
    now = local.entries['req_1']!.createdAt.add(const Duration(minutes: 3));
    expect(await repository.flush(), isNull);
    expect(local.entries, isEmpty);
  });

  test('a parked entry waits for a forced flush, not a timer', () async {
    stubPut(() async => throw const NoInternetException());
    await repository.enqueue(ok);
    await repository.flush();
    now = now.add(const Duration(minutes: 1));

    stubPut(() async {});
    expect(await repository.flush(), isNull);
    expect(local.entries.keys, ['req_1']);

    await repository.flush(force: true);
    expect(local.entries, isEmpty);
  });

  test('a backing-off entry is not retried before it is due', () async {
    stubPut(() async => throw const ServerException('x', 404));
    await repository.enqueue(ok);
    await repository.flush();

    now = now.add(const Duration(seconds: 1));
    expect(await repository.flush(), const Duration(seconds: 1));
    verify(
      () => remote.putTranscript(
        requestId: any(named: 'requestId'),
        status: any(named: 'status'),
        text: any(named: 'text'),
        locale: any(named: 'locale'),
      ),
    ).called(1);
  });

  for (final code in [400, 403, 422]) {
    test('$code drops the entry for good', () async {
      stubPut(() async => throw ServerException('x', code));
      await repository.enqueue(ok);

      expect(await repository.flush(), isNull);
      expect(local.entries, isEmpty);
    });
  }

  for (final error in <Exception>[
    const NoInternetException(),
    const ServerException('x', 503),
    const ServerException('x', 429),
    const AuthException(),
  ]) {
    test('keeps the entry parked on $error and stops the pass', () async {
      stubPut(() async => throw error);
      await repository.enqueue(ok);
      now = now.add(const Duration(seconds: 1));
      await repository.enqueue(
        const PttTranscript(
          requestId: 'req_2',
          status: PttTranscriptStatus.failed,
        ),
      );

      expect(await repository.flush(), isNull);

      expect(local.entries.keys, ['req_1', 'req_2']);
      expect(local.entries['req_1']!.state, 'parked');
      verify(
        () => remote.putTranscript(
          requestId: any(named: 'requestId'),
          status: any(named: 'status'),
          text: any(named: 'text'),
          locale: any(named: 'locale'),
        ),
      ).called(1);
    });
  }

  test('deduplicates by requestId (the latest report wins)', () async {
    await repository.enqueue(
      const PttTranscript(
        requestId: 'req_1',
        status: PttTranscriptStatus.failed,
      ),
    );
    await repository.enqueue(ok);

    expect(local.entries.length, 1);
    expect(local.entries['req_1']!.status, 'ok');
  });

  test('drops entries older than 24 h without uploading them', () async {
    await repository.enqueue(ok);
    now = now.add(const Duration(hours: 24, minutes: 1));

    await repository.flush(force: true);

    expect(local.entries, isEmpty);
    verifyNever(
      () => remote.putTranscript(
        requestId: any(named: 'requestId'),
        status: any(named: 'status'),
        text: any(named: 'text'),
        locale: any(named: 'locale'),
      ),
    );
  });

  test('keeps at most 50 entries, dropping the oldest', () async {
    for (var i = 0; i < 52; i++) {
      now = now.add(const Duration(seconds: 1));
      await repository.enqueue(
        PttTranscript(requestId: 'req_$i', status: PttTranscriptStatus.failed),
      );
    }

    expect(local.entries.length, PttTranscriptRepositoryImpl.maxEntries);
    expect(local.entries.containsKey('req_0'), isFalse);
    expect(local.entries.containsKey('req_1'), isFalse);
    expect(local.entries.containsKey('req_51'), isTrue);
  });

  test(
    'an upload that races a logout wipe does not re-create the entry',
    () async {
      stubPut(() async {
        await local.clearCache();
        throw const ServerException('x', 404);
      });
      await repository.enqueue(ok);

      await repository.flush();

      expect(local.entries, isEmpty);
    },
  );
}
