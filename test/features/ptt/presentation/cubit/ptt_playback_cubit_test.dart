import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/services/ptt_audio_player.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_recording_fixtures.dart';

class MockRepository extends Mock implements PttRecordingRepository {}

class FakePlayer implements PttAudioPlayer {
  final position = StreamController<Duration>.broadcast();
  final completed = StreamController<void>.broadcast();
  final calls = <String>[];
  bool failToLoad = false;

  @override
  Stream<Duration> get positionStream => position.stream;

  @override
  Stream<void> get completedStream => completed.stream;

  @override
  Future<void> load(String filePath) async {
    calls.add('load:$filePath');
    if (failToLoad) throw StateError('unsupported');
  }

  @override
  void play() => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration p) async => calls.add('seek:${p.inSeconds}');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  late MockRepository repository;
  late FakePlayer player;
  late PttPlaybackCubit cubit;

  setUp(() {
    repository = MockRepository();
    player = FakePlayer();
    when(() => repository.clearAudioCache()).thenAnswer((_) async {});
    when(() => repository.fetchAudio(any())).thenAnswer(
      (inv) async => Right('/tmp/${inv.positionalArguments[0]}.ogg'),
    );
    cubit = PttPlaybackCubit(repository: repository, player: player);
  });

  tearDown(() => cubit.close());

  test('tapping a recording downloads, loads and plays it', () async {
    await cubit.toggle(recording('a'));

    expect(cubit.state.activeId, 'a');
    expect(cubit.state.status, PttPlaybackStatus.playing);
    expect(player.calls, containsAllInOrder(['load:/tmp/a.ogg', 'play']));
  });

  test('tapping the playing recording pauses, again resumes', () async {
    await cubit.toggle(recording('a'));

    await cubit.toggle(recording('a'));
    expect(cubit.state.status, PttPlaybackStatus.paused);
    expect(player.calls.last, 'pause');

    await cubit.toggle(recording('a'));
    expect(cubit.state.status, PttPlaybackStatus.playing);
    expect(player.calls.last, 'play');
    verify(() => repository.fetchAudio('a')).called(1);
  });

  test(
    'only one recording plays: starting another replaces the first',
    () async {
      await cubit.toggle(recording('a'));
      await cubit.toggle(recording('b'));

      expect(cubit.state.activeId, 'b');
      expect(cubit.state.isActive('a'), isFalse);
      expect(
        player.calls,
        containsAllInOrder([
          'load:/tmp/a.ogg',
          'play',
          'stop',
          'load:/tmp/b.ogg',
        ]),
      );
    },
  );

  test('position ticks update only while playing', () async {
    await cubit.toggle(recording('a'));

    player.position.add(const Duration(seconds: 3));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.position, const Duration(seconds: 3));

    await cubit.toggle(recording('a')); // pause
    player.position.add(const Duration(seconds: 9));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.position, const Duration(seconds: 3));
  });

  // Regression: just_audio guesses ahead from the play() call and the native
  // player's first real reports land behind the guess. Replays that sequence.
  test('the start of playback never moves the position backwards', () async {
    final seen = <Duration>[];
    final sub = cubit.stream.listen((s) => seen.add(s.position));
    await cubit.toggle(recording('a'));

    for (final ms in [0, 120, 240, 30, 60, 260, 280]) {
      player.position.add(Duration(milliseconds: ms));
    }
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThanOrEqualTo(seen[i - 1]), reason: '$seen');
    }
    expect(cubit.state.position, const Duration(milliseconds: 280));
  });

  test(
    'a seek back is kept, and stale positions during it are ignored',
    () async {
      final seek = Completer<void>();
      final slowPlayer = _SlowSeekPlayer(seek.future);
      final c = PttPlaybackCubit(repository: repository, player: slowPlayer);
      addTearDown(c.close);
      await c.toggle(recording('a'));
      slowPlayer.position.add(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      final pending = c.seek('a', const Duration(seconds: 2));
      slowPlayer.position.add(const Duration(milliseconds: 5100));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.position, const Duration(seconds: 2));

      seek.complete();
      await pending;
      slowPlayer.position.add(const Duration(milliseconds: 2050));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.position, const Duration(milliseconds: 2050));
    },
  );

  test('seek moves the loaded recording only', () async {
    await cubit.seek('a', const Duration(seconds: 2));
    expect(player.calls, isEmpty);

    await cubit.toggle(recording('a'));
    await cubit.seek('a', const Duration(seconds: 5));
    await cubit.seek('b', const Duration(seconds: 7));

    expect(cubit.state.position, const Duration(seconds: 5));
    expect(player.calls.where((c) => c.startsWith('seek')), ['seek:5']);
  });

  test('finishing playback returns to idle', () async {
    await cubit.toggle(recording('a'));

    player.completed.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeId, isNull);
    expect(cubit.state.status, PttPlaybackStatus.idle);
  });

  test('a download failure resets to idle with a message', () async {
    when(
      () => repository.fetchAudio('a'),
    ).thenAnswer((_) async => const Left(NoInternetFailure()));

    await cubit.toggle(recording('a'));

    expect(cubit.state.status, PttPlaybackStatus.idle);
    expect(cubit.state.error, isNotNull);
    expect(player.calls, isNot(contains('play')));
  });

  test('a file the player rejects reports it', () async {
    player.failToLoad = true;

    await cubit.toggle(recording('a'));

    expect(cubit.state.status, PttPlaybackStatus.idle);
    expect(cubit.state.error, 'Rekaman tidak dapat diputar.');
  });

  test('a slow download of a replaced recording is dropped', () async {
    final slow = Completer<Either<Failure, String>>();
    when(() => repository.fetchAudio('a')).thenAnswer((_) => slow.future);

    final first = cubit.toggle(recording('a'));
    await cubit.toggle(recording('b'));
    slow.complete(const Right('/tmp/a.ogg'));
    await first;

    expect(cubit.state.activeId, 'b');
    expect(player.calls, isNot(contains('load:/tmp/a.ogg')));
  });

  test('stopIfActive stops only the matching recording', () async {
    await cubit.toggle(recording('a'));

    await cubit.stopIfActive('zzz');
    expect(cubit.state.activeId, 'a');

    await cubit.stopIfActive('a');
    expect(cubit.state.activeId, isNull);
    expect(player.calls.last, 'stop');
  });

  test('closing disposes the player and clears the downloaded audio', () async {
    await cubit.close();

    expect(player.calls, contains('dispose'));
    verify(() => repository.clearAudioCache()).called(1);
  });
}

class _SlowSeekPlayer extends FakePlayer {
  _SlowSeekPlayer(this._seekDone);

  final Future<void> _seekDone;

  @override
  Future<void> seek(Duration p) => _seekDone;
}
