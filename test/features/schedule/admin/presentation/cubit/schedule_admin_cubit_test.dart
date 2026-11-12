import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/repositories/schedule_admin_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ScheduleAdminRepository {}

ManagedScheduleEntity _row(String id, DateTime date, {String shift = 'a'}) =>
    ManagedScheduleEntity(
      id: id,
      date: date,
      email: '$id@x.id',
      name: 'N$id',
      isMember: true,
      locked: false,
      shiftUid: shift,
      shiftColor: shift == 'a' ? '#3B82F6' : '#10B981',
    );

void main() {
  late _MockRepository repository;
  late ScheduleAdminCubit cubit;

  setUp(() {
    repository = _MockRepository();
    cubit = ScheduleAdminCubit(
      repository: repository,
      clock: () => DateTime(2026, 11, 10, 9),
    );
  });

  tearDown(() => cubit.close());

  void stub(Either<Failure, List<ManagedScheduleEntity>> result) => when(
    () => repository.getSchedules(
      from: any(named: 'from'),
      to: any(named: 'to'),
      email: any(named: 'email'),
    ),
  ).thenAnswer((_) async => result);

  test('starts on today in its month', () {
    expect(cubit.state.month, DateTime(2026, 11));
    expect(cubit.state.selectedDay, DateTime(2026, 11, 10));
  });

  test('loads the whole Monday-to-Sunday grid of the month', () async {
    stub(Right([_row('1', DateTime(2026, 11, 11))]));

    await cubit.load();

    // 1 Nov 2026 is a Sunday: the grid starts Monday 26 Oct, ends Sunday 6 Dec.
    verify(
      () => repository.getSchedules(
        from: DateTime(2026, 10, 26),
        to: DateTime(2026, 12, 6),
      ),
    ).called(1);
    expect(cubit.state.status, ScheduleAdminStatus.loaded);
    expect(cubit.state.itemsOn(DateTime(2026, 11, 11)), hasLength(1));
  });

  test('a failure shows the server message', () async {
    stub(const Left(ServerFailure('Akses ditolak.', 403)));

    await cubit.load();

    expect(cubit.state.status, ScheduleAdminStatus.error);
    expect(cubit.state.message, 'Akses ditolak.');
  });

  test('a silent reload failure keeps the content', () async {
    stub(Right([_row('1', DateTime(2026, 11, 11))]));
    await cubit.load();
    stub(const Left(ServerFailure('x')));

    final ok = await cubit.load(silent: true);

    expect(ok, isFalse);
    expect(cubit.state.status, ScheduleAdminStatus.loaded);
    expect(cubit.state.items, hasLength(1));
  });

  test('goToMonth moves, selects the 1st and reloads', () async {
    stub(const Right([]));

    await cubit.goToMonth(DateTime(2026, 12, 20));

    expect(cubit.state.month, DateTime(2026, 12));
    expect(cubit.state.selectedDay, DateTime(2026, 12));
    verify(
      () => repository.getSchedules(
        from: DateTime(2026, 11, 30),
        to: DateTime(2027, 1, 3),
      ),
    ).called(1);
  });

  test('selecting a day of another month switches month', () async {
    stub(const Right([]));

    await cubit.selectDay(DateTime(2026, 10, 28));

    expect(cubit.state.month, DateTime(2026, 10));
    expect(cubit.state.selectedDay, DateTime(2026, 10, 28));
  });

  test('selecting a day in the month does not hit the server', () async {
    await cubit.selectDay(DateTime(2026, 11, 20));

    expect(cubit.state.selectedDay, DateTime(2026, 11, 20));
    verifyZeroInteractions(repository);
  });

  test('person filter is sent as email and can be cleared', () async {
    stub(const Right([]));

    await cubit.setPersonFilter(email: 'a@x.id', name: 'A');
    verify(
      () => repository.getSchedules(
        from: any(named: 'from'),
        to: any(named: 'to'),
        email: 'a@x.id',
      ),
    ).called(1);

    await cubit.setPersonFilter();
    expect(cubit.state.filterEmail, isNull);
  });

  test('shiftColorsOn gives one colour per distinct shift', () async {
    final day = DateTime(2026, 11, 11);
    stub(Right([_row('1', day), _row('2', day), _row('3', day, shift: 'b')]));

    await cubit.load();

    expect(cubit.state.shiftColorsOn(day), ['#3B82F6', '#10B981']);
  });

  test('deleteMany reloads and returns the counts', () async {
    stub(const Right([]));
    when(() => repository.deleteMany(any())).thenAnswer(
      (_) async =>
          const Right(DeleteSchedulesResult(deletedCount: 1, skippedCount: 1)),
    );

    final result = await cubit.deleteMany(['1', '2']);

    expect(result.toNullable()?.skippedCount, 1);
    verify(() => repository.deleteMany(['1', '2'])).called(1);
    verify(
      () => repository.getSchedules(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).called(1);
  });
}
