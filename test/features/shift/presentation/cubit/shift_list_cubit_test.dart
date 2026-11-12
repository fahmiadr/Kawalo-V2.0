import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ShiftRepository {}

const _shift = ShiftEntity(
  uid: 'a',
  name: 'Shift Pagi',
  startTime: ShiftClock(7, 0),
  endTime: ShiftClock(15, 0),
  color: '#F2A900',
);

void main() {
  late _MockRepository repository;
  late ShiftListCubit cubit;

  setUp(() {
    repository = _MockRepository();
    cubit = ShiftListCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  void stub(Either<Failure, List<ShiftEntity>> result) =>
      when(() => repository.getShifts()).thenAnswer((_) async => result);

  test('emits loading then loaded', () async {
    stub(const Right([_shift]));
    final states = <ShiftListState>[];
    final sub = cubit.stream.listen(states.add);

    expect(await cubit.fetch(), isTrue);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states, const [
      ShiftListLoading(),
      ShiftListLoaded([_shift]),
    ]);
  });

  test('emits an error with the failure message', () async {
    stub(const Left(NoInternetFailure()));

    expect(await cubit.fetch(), isFalse);

    expect(cubit.state, isA<ShiftListError>());
  });

  test('a silent refresh keeps the list on screen while loading', () async {
    stub(const Right([_shift]));
    await cubit.fetch();

    final states = <ShiftListState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.fetch(silent: true);
    await sub.cancel();

    expect(states.whereType<ShiftListLoading>(), isEmpty);
  });

  test('a failed silent refresh keeps the loaded list', () async {
    stub(const Right([_shift]));
    await cubit.fetch();
    stub(const Left(NoInternetFailure()));

    expect(await cubit.fetch(silent: true), isFalse);

    expect(cubit.state, const ShiftListLoaded([_shift]));
  });

  test('a stale response does not overwrite a newer one', () async {
    final slow = Future<Either<Failure, List<ShiftEntity>>>.delayed(
      const Duration(milliseconds: 20),
      () => const Right([]),
    );
    when(() => repository.getShifts()).thenAnswer((_) => slow);
    final first = cubit.fetch();
    stub(const Right([_shift]));
    await cubit.fetch();
    await first;

    expect(cubit.state, const ShiftListLoaded([_shift]));
  });
}
