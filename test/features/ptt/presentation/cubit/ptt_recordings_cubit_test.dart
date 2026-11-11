import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_recording_page.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_recording_fixtures.dart';

class MockRepository extends Mock implements PttRecordingRepository {}

void main() {
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
  });

  void stubPage(PttRecordingPage page, {String? before}) {
    when(
      () => repository.getRecordings(
        before: before,
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => Right(page));
  }

  PttRecordingsCubit build() => PttRecordingsCubit(repository: repository);

  group('load', () {
    blocTest<PttRecordingsCubit, PttRecordingsState>(
      'loads the first page',
      build: build,
      setUp: () =>
          stubPage(PttRecordingPage(items: [recording('a')], nextBefore: 'c1')),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, PttRecordingsStatus.loaded);
        expect(cubit.state.items.map((r) => r.id), ['a']);
        expect(cubit.state.hasMore, isTrue);
      },
    );

    blocTest<PttRecordingsCubit, PttRecordingsState>(
      'an empty history is loaded, not an error',
      build: build,
      setUp: () => stubPage(const PttRecordingPage(items: [])),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, PttRecordingsStatus.loaded);
        expect(cubit.state.items, isEmpty);
        expect(cubit.state.hasMore, isFalse);
      },
    );

    blocTest<PttRecordingsCubit, PttRecordingsState>(
      'a failure with nothing shown becomes the error state',
      build: build,
      setUp: () => when(
        () => repository.getRecordings(
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('Gagal.'))),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, PttRecordingsStatus.failure);
        expect(cubit.state.errorMessage, 'Gagal.');
      },
    );
  });

  group('loadMore', () {
    test('appends the older page, drops duplicates and ends at null', () async {
      stubPage(PttRecordingPage(items: [recording('a')], nextBefore: 'c1'));
      stubPage(
        PttRecordingPage(items: [recording('a'), recording('b')]),
        before: 'c1',
      );
      final cubit = build();
      await cubit.load();

      await cubit.loadMore();

      expect(cubit.state.items.map((r) => r.id), ['a', 'b']);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.isLoadingMore, isFalse);

      await cubit.loadMore();
      verify(
        () => repository.getRecordings(
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        ),
      ).called(2);
    });

    test(
      'a failed page keeps the list and the cursor, with a notice',
      () async {
        stubPage(PttRecordingPage(items: [recording('a')], nextBefore: 'c1'));
        when(
          () => repository.getRecordings(
            before: 'c1',
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Left(NoInternetFailure()));
        final cubit = build();
        await cubit.load();

        await cubit.loadMore();

        expect(cubit.state.items, hasLength(1));
        expect(cubit.state.nextBefore, 'c1');
        expect(cubit.state.isLoadingMore, isFalse);
        expect(cubit.state.notice, isNotNull);
      },
    );
  });

  group('refresh', () {
    test('replaces the list with the newest page', () async {
      stubPage(PttRecordingPage(items: [recording('a')]));
      final cubit = build();
      await cubit.load();
      stubPage(PttRecordingPage(items: [recording('n'), recording('a')]));

      await cubit.refresh();

      expect(cubit.state.items.map((r) => r.id), ['n', 'a']);
    });

    test('a failed refresh keeps the list and raises a notice', () async {
      stubPage(PttRecordingPage(items: [recording('a')]));
      final cubit = build();
      await cubit.load();
      when(
        () => repository.getRecordings(
          before: any(named: 'before'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(NoInternetFailure()));

      await cubit.refresh();

      expect(cubit.state.status, PttRecordingsStatus.loaded);
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.notice, isNotNull);
    });
  });

  group('delete', () {
    test('an admin deletes and the recording leaves the list', () async {
      stubPage(PttRecordingPage(items: [recording('a'), recording('b')]));
      when(
        () => repository.deleteRecording('a'),
      ).thenAnswer((_) async => const Right(null));
      final cubit = build();
      await cubit.load();

      final deleted = await cubit.delete('a', session: session(admin: true));

      expect(deleted, isTrue);
      expect(cubit.state.items.map((r) => r.id), ['b']);
      expect(cubit.state.deletingIds, isEmpty);
    });

    test('a non-admin never reaches the repository', () async {
      stubPage(PttRecordingPage(items: [recording('a')]));
      final cubit = build();
      await cubit.load();

      final deleted = await cubit.delete('a', session: session());
      final withoutSession = await cubit.delete('a', session: null);

      expect(deleted, isFalse);
      expect(withoutSession, isFalse);
      expect(cubit.state.items, hasLength(1));
      verifyNever(() => repository.deleteRecording(any()));
    });

    test('a server failure keeps the recording and says why', () async {
      stubPage(PttRecordingPage(items: [recording('a')]));
      when(
        () => repository.deleteRecording('a'),
      ).thenAnswer((_) async => const Left(ServerFailure('Ditolak.')));
      final cubit = build();
      await cubit.load();

      final deleted = await cubit.delete('a', session: session(admin: true));

      expect(deleted, isFalse);
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.notice, 'Ditolak.');
      expect(cubit.state.deletingIds, isEmpty);
    });
  });
}
