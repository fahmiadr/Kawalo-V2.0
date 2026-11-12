import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/repositories/schedule_admin_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ScheduleAdminRepository {}

class _MockGroup extends Mock implements GroupRepository {}

ScheduleEntry _entry(int day) => ScheduleEntry(
  email: 'a@x.id',
  shiftUid: 's1',
  date: DateTime(2026, 11, day),
);

void main() {
  late _MockRepository repository;
  late _MockGroup groupRepo;
  late ScheduleFormCubit cubit;

  setUpAll(() => registerFallbackValue(_entry(1)));

  setUp(() {
    repository = _MockRepository();
    groupRepo = _MockGroup();
    cubit = ScheduleFormCubit(
      repository: repository,
      groupRepository: groupRepo,
    );
  });

  tearDown(() => cubit.close());

  group('loadOptions', () {
    test('loads members and shifts', () async {
      when(() => groupRepo.getMembers()).thenAnswer(
        (_) async => const Right([
          GroupMemberEntity(email: 'a@x.id', name: 'A', role: 'GUARD'),
        ]),
      );
      when(() => repository.getShifts()).thenAnswer(
        (_) async => const Right([
          ShiftOptionEntity(
            uid: 's1',
            name: 'Pagi',
            startTime: '07:00',
            endTime: '15:00',
          ),
        ]),
      );

      await cubit.loadOptions();

      expect(cubit.state.status, ScheduleFormStatus.ready);
      expect(cubit.state.members.single.role, 'GUARD');
      expect(cubit.state.shifts.single.uid, 's1');
    });

    test('either failing shows its message', () async {
      when(
        () => groupRepo.getMembers(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => repository.getShifts(),
      ).thenAnswer((_) async => const Left(NoInternetFailure()));

      await cubit.loadOptions();

      expect(cubit.state.status, ScheduleFormStatus.optionsError);
      expect(cubit.state.message, isNotEmpty);
    });
  });

  group('submit', () {
    test('one entry uses the single create call', () async {
      when(
        () => repository.create(any(), overwrite: any(named: 'overwrite')),
      ).thenAnswer((_) async => const Right(unit));

      await cubit.submit([_entry(11)]);

      expect(cubit.state.status, ScheduleFormStatus.saved);
      verify(() => repository.create(_entry(11))).called(1);
    });

    test('several entries use bulk and summarise the result', () async {
      when(
        () => repository.createBulk(any(), overwrite: any(named: 'overwrite')),
      ).thenAnswer(
        (_) async => const Right(
          BulkScheduleResult(
            created: 12,
            replaced: 0,
            skipped: 2,
            skippedItems: [
              SkippedEntry(index: 1, reason: 'Sudah ada'),
              SkippedEntry(
                index: 2,
                reason: 'Sudah punya shift lain pada tanggal ini',
                code: 'SCHEDULE_OTHER_SHIFT',
              ),
            ],
          ),
        ),
      );

      await cubit.submit([_entry(11), _entry(12)]);

      expect(cubit.state.status, ScheduleFormStatus.saved);
      expect(cubit.state.message, startsWith('12 jadwal dibuat, 2 dilewati'));
      expect(cubit.state.result?.otherShiftSkips, 1);
    });

    test('an edit calls update with the row id', () async {
      when(
        () => repository.update(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      await cubit.submit([_entry(11)], editingId: '9');

      verify(() => repository.update('9', _entry(11))).called(1);
    });

    test('the other-shift 409 can be overwritten', () async {
      when(
        () => repository.create(any(), overwrite: any(named: 'overwrite')),
      ).thenAnswer(
        (_) async => const Left(
          ServerFailure(
            'Personil sudah punya jadwal shift lain pada tanggal ini.',
            409,
            'SCHEDULE_OTHER_SHIFT',
          ),
        ),
      );

      await cubit.submit([_entry(11)]);

      expect(cubit.state.status, ScheduleFormStatus.failed);
      expect(cubit.state.canOverwrite, isTrue);
      expect(cubit.state.message, contains('shift lain'));
    });

    test('a duplicate 409 shows the message but offers no overwrite', () async {
      when(
        () => repository.create(any(), overwrite: any(named: 'overwrite')),
      ).thenAnswer(
        (_) async => const Left(
          ServerFailure(
            'Jadwal personil ini pada tanggal dan shift tersebut sudah ada.',
            409,
          ),
        ),
      );

      await cubit.submit([_entry(11)]);

      expect(cubit.state.canOverwrite, isFalse);
      expect(cubit.state.message, contains('sudah ada'));
    });

    test('overwrite is forwarded only when asked', () async {
      when(
        () => repository.create(any(), overwrite: any(named: 'overwrite')),
      ).thenAnswer((_) async => const Right(unit));

      await cubit.submit([_entry(11)], overwrite: true);

      verify(() => repository.create(_entry(11), overwrite: true)).called(1);
    });

    test('more than 1000 entries never reach the server', () async {
      await cubit.submit([for (var i = 0; i < 1001; i++) _entry(11)]);

      expect(cubit.state.status, ScheduleFormStatus.failed);
      expect(cubit.state.message, contains('1000'));
      verifyZeroInteractions(repository);
    });
  });
}
