import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/get_information/get_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_result.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationRepository extends Mock implements InformationRepository {}

void main() {
  late GetInformationUseCase getInformationUseCase;
  late MockInformationRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const GetInformationParams());
  });

  setUp(() {
    mockRepository = MockInformationRepository();
    getInformationUseCase = GetInformationUseCase(mockRepository);
  });

  const tEntity = InformationItemEntity(
    id: '1',
    photos: [],
    title: 'Pemeriksaan Pos Jaga',
    text: 'Aman terkendali.',
    userEmail: 'satpam@kawalo.id',
    userName: 'Budi Santoso',
    feedDt: '09 Sep 2026 14:20',
    feedType: 'GENERAL',
    groupName: 'JKN Veranda',
    glat: -6.2,
    glong: 106.816666,
  );
  const tResult = InformationResult(
    items: [tEntity],
  );

  group('GetInformationUseCase Tests', () {
    test('returns InformationResult on success', () async {
      const tParams = GetInformationParams(search: 'Pos Jaga');
      when(
        () => mockRepository.getInformation(any()),
      ).thenAnswer(
        (_) async => const Right(tResult),
      );

      final result = await getInformationUseCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be Right'),
        (resultEntity) {
          expect(resultEntity.items.length, 1);
          expect(resultEntity.items.first.title, 'Pemeriksaan Pos Jaga');
          expect(resultEntity.isFromCache, isFalse);
        },
      );
      verify(
        () => mockRepository.getInformation(tParams),
      ).called(1);
    });

    test('returns Failure when repository fails', () async {
      const tFailure = ServerFailure('Gagal memuat feed');
      const tParams = GetInformationParams();
      when(
        () => mockRepository.getInformation(any()),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await getInformationUseCase(tParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Gagal memuat feed'),
        (_) => fail('Should be Left'),
      );
      verify(
        () => mockRepository.getInformation(tParams),
      ).called(1);
    });
  });
}
