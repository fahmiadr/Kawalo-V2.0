import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_attendance_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AttendanceCheckRepository {}

final _now = DateTime(2026, 11, 13, 9);
final _slot = AttendanceSlot(
  date: DateTime(2026, 11, 13),
  shiftName: 'Shift Pagi',
  startTime: '07:00',
  endTime: '15:00',
  checkin: '06:52:10',
);

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  blocTest<HomeAttendanceCubit, HomeAttendanceState>(
    'plans check-out for a shift already checked in',
    setUp: () => when(
      () => repository.getSlots(_now),
    ).thenAnswer((_) async => Right([_slot])),
    build: () => HomeAttendanceCubit(repository: repository, clock: () => _now),
    act: (cubit) => cubit.load(),
    expect: () => [
      HomeAttendanceLoaded(
        AttendancePlan.act(_slot, AttendanceAction.checkOut),
      ),
    ],
  );

  blocTest<HomeAttendanceCubit, HomeAttendanceState>(
    'no slots means no schedule',
    setUp: () => when(
      () => repository.getSlots(_now),
    ).thenAnswer((_) async => const Right([])),
    build: () => HomeAttendanceCubit(repository: repository, clock: () => _now),
    act: (cubit) => cubit.load(),
    expect: () => [const HomeAttendanceLoaded(AttendancePlan.noSchedule())],
  );

  blocTest<HomeAttendanceCubit, HomeAttendanceState>(
    'a failure is reported, not thrown',
    setUp: () => when(
      () => repository.getSlots(_now),
    ).thenAnswer((_) async => const Left(NoInternetFailure())),
    build: () => HomeAttendanceCubit(repository: repository, clock: () => _now),
    act: (cubit) => cubit.load(),
    expect: () => [const HomeAttendanceFailed()],
  );
}
