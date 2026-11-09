import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/stop_transmission/stop_transmission_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/stop_transmission/stop_transmission_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPttRepository extends Mock implements PttRepository {}

void main() {
  late MockPttRepository mockRepository;
  late StopTransmissionUseCase useCase;

  setUp(() {
    mockRepository = MockPttRepository();
    useCase = StopTransmissionUseCase(mockRepository);
  });

  group('StopTransmissionUseCase', () {
    test('mendelegasikan stopTransmission ke repositori', () async {
      when(
        () => mockRepository.stopTransmission(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(const StopTransmissionParams());

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.stopTransmission()).called(1);
    });

    test('meneruskan failure jika stopTransmission gagal', () async {
      when(
        () => mockRepository.stopTransmission(),
      ).thenAnswer((_) async => const Left(ServerFailure('Service error')));

      final result = await useCase(const StopTransmissionParams());

      expect(result, const Left<Failure, void>(ServerFailure('Service error')));
    });
  });
}
