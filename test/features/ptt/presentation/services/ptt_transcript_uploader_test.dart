import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_transcript_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_transcript_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_transcript.dart';
import 'package:kawalo_mobile/features/ptt/presentation/services/ptt_transcript_uploader.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_transcript_fakes.dart';

class MockRemote extends Mock implements PttTranscriptRemoteDataSource {}

class MockRepository extends Mock implements PttTranscriptRepository {}

const session = AuthSessionEntity(
  userId: 'usr_1',
  email: 'a@kawalo.id',
  name: 'A',
  allowAdmin: false,
  allowPatrol: false,
  allowMonPatrol: false,
  groupUid: 'grp_1',
);

const failed = PttTranscript(
  requestId: 'req_1',
  status: PttTranscriptStatus.failed,
  reason: 'on_device_no_match',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRemote remote;
  late FakeTranscriptLocalDataSource local;
  late StreamController<PttTranscript> transcripts;
  late StreamController<bool> connectivity;
  late UserSessionCubit sessionCubit;
  late PttTranscriptUploader uploader;

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

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() {
    remote = MockRemote();
    local = FakeTranscriptLocalDataSource();
    transcripts = StreamController<PttTranscript>.broadcast();
    connectivity = StreamController<bool>.broadcast();
    sessionCubit = UserSessionCubit(session);
    uploader = PttTranscriptUploader(
      repository: PttTranscriptRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      ),
      transcripts: transcripts.stream,
      connectivity: connectivity.stream,
      session: sessionCubit,
    );
  });

  tearDown(() async {
    await uploader.dispose();
    await transcripts.close();
    await connectivity.close();
    await sessionCubit.close();
  });

  test('event -> queue -> upload -> removed', () async {
    stubPut(() async {});
    uploader.start();

    transcripts.add(failed);
    await settle();

    verify(
      () => remote.putTranscript(requestId: 'req_1', status: 'failed'),
    ).called(1);
    expect(local.entries, isEmpty);
  });

  test('drops reports that arrive without a session', () async {
    sessionCubit.clearSession();
    uploader.start();

    transcripts.add(failed);
    await settle();

    expect(local.entries, isEmpty);
    verifyNever(
      () => remote.putTranscript(
        requestId: any(named: 'requestId'),
        status: any(named: 'status'),
      ),
    );
  });

  test('keeps a report queued offline and sends it when back online', () async {
    stubPut(() async => throw const NoInternetException());
    uploader.start();
    transcripts.add(failed);
    await settle();
    expect(local.entries.keys, ['req_1']);

    stubPut(() async {});
    connectivity
      ..add(false)
      ..add(true);
    await settle();

    expect(local.entries, isEmpty);
  });

  test('retries a parked report on app resume', () async {
    stubPut(() async => throw const ServerException('x', 503));
    uploader.start();
    transcripts.add(failed);
    await settle();
    expect(local.entries.keys, ['req_1']);

    stubPut(() async {});
    uploader.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();

    expect(local.entries, isEmpty);
  });

  test('flushes what is left from a previous run on start', () async {
    stubPut(() async {});
    await PttTranscriptRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    ).enqueue(failed);

    uploader.start();
    await settle();

    expect(local.entries, isEmpty);
  });

  test('flushes once a session with a group appears (login)', () async {
    stubPut(() async {});
    sessionCubit.clearSession();
    await PttTranscriptRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    ).enqueue(failed);
    uploader.start();
    await settle();
    expect(local.entries.keys, ['req_1']);

    sessionCubit.updateSession(session);
    await settle();

    expect(local.entries, isEmpty);
  });

  test('logout wipe empties the queue', () async {
    stubPut(() async => throw const NoInternetException());
    uploader.start();
    transcripts.add(failed);
    await settle();

    await CacheWiper(wipeables: [local]).wipeAll();

    expect(local.entries, isEmpty);
  });

  test(
    're-flushes by timer while the server has not written the recording',
    () async {
      final repository = MockRepository();
      var calls = 0;
      when(() => repository.flush(force: any(named: 'force'))).thenAnswer(
        (_) async => ++calls == 1 ? const Duration(milliseconds: 10) : null,
      );
      final timed = PttTranscriptUploader(
        repository: repository,
        transcripts: const Stream.empty(),
        connectivity: const Stream.empty(),
        session: sessionCubit,
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(calls, 2);
      verify(() => repository.flush(force: true)).called(1);
      verify(repository.flush).called(1);
      await timed.dispose();
    },
  );
}
