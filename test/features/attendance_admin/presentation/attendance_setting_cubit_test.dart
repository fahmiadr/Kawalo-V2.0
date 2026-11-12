import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_setting_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;
  late AttendanceSettingCubit cubit;

  setUp(() {
    repository = MockRepository();
    cubit = AttendanceSettingCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  void stubLoad([AttendanceSettingEntity? setting]) => when(
    () => repository.getSetting(),
  ).thenAnswer((_) async => Right(setting ?? attendanceSetting()));

  test('load puts the server value on the slider', () async {
    stubLoad(attendanceSetting(percent: 55, isDefault: false));

    await cubit.load();

    expect(cubit.state.phase, AttendanceSettingPhase.loaded);
    expect(cubit.state.draft, 55);
    expect(cubit.state.isDirty, isFalse);
  });

  test('a failed load shows the error and can be retried', () async {
    when(
      () => repository.getSetting(),
    ).thenAnswer((_) async => const Left(ServerFailure('Gagal.')));

    await cubit.load();

    expect(cubit.state.phase, AttendanceSettingPhase.failure);
    expect(cubit.state.errorMessage, 'Gagal.');

    stubLoad();
    await cubit.load();
    expect(cubit.state.phase, AttendanceSettingPhase.loaded);
  });

  test(
    'changeDraft clamps to the API range and marks the form dirty',
    () async {
      stubLoad();
      await cubit.load();

      cubit.changeDraft(70);
      expect(cubit.state.draft, 70);
      expect(cubit.state.isDirty, isTrue);

      cubit.changeDraft(5);
      expect(cubit.state.draft, 20);
      cubit.changeDraft(200);
      expect(cubit.state.draft, 95);

      cubit.changeDraft(40);
      expect(cubit.state.isDirty, isFalse);
    },
  );

  test('save sends the draft and reports success', () async {
    stubLoad();
    await cubit.load();
    when(() => repository.saveSetting(65)).thenAnswer(
      (_) async => Right(attendanceSetting(percent: 65, isDefault: false)),
    );

    cubit.changeDraft(65);
    await cubit.save();

    expect(cubit.state.saving, isFalse);
    expect(cubit.state.setting?.faceMatchPercent, 65);
    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.notice, AttendanceSettingCubit.savedMessage);
    expect(cubit.state.noticeSeq, 1);
  });

  test('a failed save keeps the draft and shows the message', () async {
    stubLoad();
    await cubit.load();
    when(() => repository.saveSetting(any())).thenAnswer(
      (_) async => const Left(ServerFailure('Persentase tidak valid.', 422)),
    );

    cubit.changeDraft(65);
    await cubit.save();

    expect(cubit.state.draft, 65);
    expect(cubit.state.isDirty, isTrue);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.notice, 'Persentase tidak valid.');
  });

  test('resetToDefault sends null and adopts the server answer', () async {
    stubLoad(attendanceSetting(percent: 60, isDefault: false));
    await cubit.load();
    when(
      () => repository.saveSetting(null),
    ).thenAnswer((_) async => Right(attendanceSetting()));

    await cubit.resetToDefault();

    verify(() => repository.saveSetting(null)).called(1);
    expect(cubit.state.draft, 40);
    expect(cubit.state.setting?.isDefault, isTrue);
  });
}
