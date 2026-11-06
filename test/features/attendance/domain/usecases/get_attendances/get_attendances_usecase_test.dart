import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kawalo_mobile/features/attendance/domain/usecases/get_attendances/get_attendances_usecase.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/attendance_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepo;
  late GetAttendancesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const GetAttendancesParams());
  });

  setUp(() {
    mockRepo = MockAttendanceRepository();
    useCase = GetAttendancesUseCase(mockRepo);
  });

  const testItem = AttendanceItemEntity(
    id: '1',
    category: 'MASUK',
    diffMinutes: 0,
    userEmail: 'guard@kawalo.id',
    userName: 'Ahmad',
    attendanceDt: '2026-09-10T07:00:00.000Z',
    attendanceType: 'CHECK IN',
    locationName: 'Pos 1',
  );

  test(
    'calls repository.getAttendances and returns Right with items',
    () async {
      const tParams = GetAttendancesParams(search: 'Ahmad');
      when(
        () => mockRepo.getAttendances(any()),
      ).thenAnswer(
        (_) async => const Right(
          AttendanceResult(items: [testItem]),
        ),
      );

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be Right'),
        (resultEntity) {
          expect(resultEntity.items.length, 1);
          expect(resultEntity.items.first.userName, 'Ahmad');
          expect(resultEntity.isFromCache, isFalse);
        },
      );

      verify(
        () => mockRepo.getAttendances(tParams),
      ).called(1);
    },
  );

  test('returns Left when repository fails', () async {
    const tParams = GetAttendancesParams();
    when(
      () => mockRepo.getAttendances(any()),
    ).thenAnswer(
      (_) async => const Left(ServerFailure('Server error')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.message, 'Server error'),
      (_) => fail('Should be Left'),
    );

    verify(
      () => mockRepo.getAttendances(tParams),
    ).called(1);
  });
}
