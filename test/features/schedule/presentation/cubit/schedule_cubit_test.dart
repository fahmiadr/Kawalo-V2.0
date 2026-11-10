import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ScheduleRepository {}

final _shift = ScheduleEntity(
  id: '1',
  date: DateTime(2026, 6, 30),
  shiftName: 'Shift Pagi',
  startTime: '08:00',
  endTime: '16:00',
);

void main() {
  late _MockRepository repository;
  late ScheduleCubit cubit;

  setUp(() {
    repository = _MockRepository();
    cubit = ScheduleCubit(
      repository: repository,
      clock: () => DateTime(2026, 6, 30, 9, 30),
    );
  });

  tearDown(() => cubit.close());

  void stub(Either<Failure, List<ScheduleEntity>> result) {
    when(
      () => repository.getMySchedules(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('requests today through today + 30 days', () async {
    stub(Right([_shift]));

    await cubit.fetch();

    verify(
      () => repository.getMySchedules(
        from: DateTime(2026, 6, 30),
        to: DateTime(2026, 7, 30),
      ),
    ).called(1);
  });

  test('emits loading then loaded', () async {
    stub(Right([_shift]));

    final states = <ScheduleState>[];
    final sub = cubit.stream.listen(states.add);
    final ok = await cubit.fetch();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(ok, isTrue);
    expect(states, [
      const ScheduleLoading(),
      ScheduleLoaded([_shift]),
    ]);
  });

  test('loaded with an empty list is a valid result', () async {
    stub(const Right([]));

    await cubit.fetch();

    expect(cubit.state, const ScheduleLoaded([]));
  });

  test('emits error with the failure message', () async {
    stub(const Left(NoInternetFailure()));

    final ok = await cubit.fetch();

    expect(ok, isFalse);
    expect(cubit.state, ScheduleError(const NoInternetFailure().message));
  });

  test('silent refresh keeps the loaded content, also on failure', () async {
    stub(Right([_shift]));
    await cubit.fetch();

    final states = <ScheduleState>[];
    final sub = cubit.stream.listen(states.add);
    stub(const Left(NoInternetFailure()));
    final ok = await cubit.fetch(silent: true);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(ok, isFalse);
    expect(states, isEmpty);
    expect(cubit.state, ScheduleLoaded([_shift]));
  });

  test(
    'silent refresh without content falls back to loading and error',
    () async {
      stub(const Left(NoInternetFailure()));

      await cubit.fetch(silent: true);

      expect(cubit.state, isA<ScheduleError>());
    },
  );
}
