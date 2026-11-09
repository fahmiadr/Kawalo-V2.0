import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/usecases/get_operationals/get_operationals_usecase.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/operational_result.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationalRepository extends Mock implements OperationalRepository {}

void main() {
  late MockOperationalRepository mockRepo;
  late GetOperationalsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const GetOperationalsParams());
  });

  setUp(() {
    mockRepo = MockOperationalRepository();
    useCase = GetOperationalsUseCase(mockRepo);
  });

  const testWorker = OperationalItemEntity(
    id: 'agus@kawalo.id_2026-09-10',
    userEmail: 'agus@kawalo.id',
    userName: 'Agus Setiawan',
    totalActivities: 2,
    timeline: [DutyTimelineEntity(id: '1', duty: 'Patroli Lingkungan')],
  );

  test(
    'calls repository.getOperationals and returns Right with items',
    () async {
      const tParams = GetOperationalsParams(search: 'Agus');
      when(() => mockRepo.getOperationals(any())).thenAnswer(
        (_) async => const Right(OperationalResult(items: [testWorker])),
      );

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should be Right'), (resultEntity) {
        expect(resultEntity.items.length, 1);
        expect(resultEntity.items.first.userName, 'Agus Setiawan');
        expect(resultEntity.isFromCache, isFalse);
      });

      verify(() => mockRepo.getOperationals(tParams)).called(1);
    },
  );

  test('returns Left when repository fails', () async {
    const tParams = GetOperationalsParams();
    when(
      () => mockRepo.getOperationals(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.message, 'Server error'),
      (_) => fail('Should be Left'),
    );

    verify(() => mockRepo.getOperationals(tParams)).called(1);
  });
}
