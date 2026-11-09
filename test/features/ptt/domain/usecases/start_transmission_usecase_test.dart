import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPttRepository extends Mock implements PttRepository {}

void main() {
  late MockPttRepository mockRepository;
  late StartTransmissionUseCase useCase;

  setUp(() {
    mockRepository = MockPttRepository();
    useCase = StartTransmissionUseCase(mockRepository);
  });

  group('StartTransmissionUseCase', () {
    test('mendelegasikan requestId ke repositori', () async {
      when(
        () => mockRepository.startTransmission(requestId: 'req_123'),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        const StartTransmissionParams(requestId: 'req_123'),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.startTransmission(requestId: 'req_123'),
      ).called(1);
    });

    test('meneruskan failure jika startTransmission gagal', () async {
      when(
        () => mockRepository.startTransmission(requestId: 'req_123'),
      ).thenAnswer((_) async => const Left(ServerFailure('Socket closed')));

      final result = await useCase(
        const StartTransmissionParams(requestId: 'req_123'),
      );

      expect(result, const Left<Failure, void>(ServerFailure('Socket closed')));
    });
  });
}
