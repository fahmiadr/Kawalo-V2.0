import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/create_information_data.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationRepository extends Mock implements InformationRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late CreateInformationUseCase useCase;
  late MockInformationRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const CreateInformationData(title: 'Fallback'));
    registerFallbackValue(const CreateInformationParams(title: 'Fallback'));
  });

  setUp(() {
    mockRepository = MockInformationRepository();
    useCase = CreateInformationUseCase(mockRepository);
  });

  const tSessionAdmin = AuthSessionEntity(
    userId: '1',
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tSessionGuard = AuthSessionEntity(
    userId: '2',
    email: 'guard@example.com',
    name: 'Guard User',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const tSessionCitizen = AuthSessionEntity(
    userId: '3',
    email: 'citizen@example.com',
    name: 'Citizen User',
    role: 'CITIZEN',
    allowAdmin: false,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tParams = CreateInformationParams(
    title: 'Pengumuman Penting',
    text: 'Akan diadakan pemadaman listrik berkala.',
    feedType: 'GENERAL',
    session: tSessionAdmin,
  );

  const tResultEntity = InformationItemEntity(
    id: '123',
    photos: [],
    title: 'Pengumuman Penting',
    text: 'Akan diadakan pemadaman listrik berkala.',
    feedType: 'GENERAL',
  );

  group('CreateInformationParams Authorization Tests', () {
    test('isAuthorized returns true for ADMIN and GUARD roles', () {
      const adminParams = CreateInformationParams(
        title: 'Info',
        session: tSessionAdmin,
      );
      expect(adminParams.isAuthorized, isTrue);

      const guardParams = CreateInformationParams(
        title: 'Info',
        session: tSessionGuard,
      );
      expect(guardParams.isAuthorized, isTrue);
    });

    test('isAuthorized returns false for null session or other roles', () {
      const nullSessionParams = CreateInformationParams(title: 'Info');
      expect(nullSessionParams.isAuthorized, isFalse);

      const citizenParams = CreateInformationParams(
        title: 'Info',
        session: tSessionCitizen,
      );
      expect(citizenParams.isAuthorized, isFalse);
    });
  });

  group('CreateInformationUseCase Execution Tests', () {
    test('returns ForbiddenFailure when caller is unauthorized', () async {
      const unauthorizedParams = CreateInformationParams(
        title: 'Pengumuman Penting',
        session: tSessionCitizen,
      );

      final result = await useCase(unauthorizedParams);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ForbiddenFailure>());
        expect(
          failure.message,
          'Anda tidak memiliki izin untuk membuat informasi.',
        );
      }, (_) => fail('Should be Left'));
      verifyZeroInteractions(mockRepository);
    });

    test('delegates to repository and returns entity on success', () async {
      when(
        () => mockRepository.createInformation(any()),
      ).thenAnswer((_) async => const Right(tResultEntity));

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be Right'),
        (entity) => expect(entity, equals(tResultEntity)),
      );

      verify(
        () => mockRepository.createInformation(tParams.toRepositoryData()),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('forwards cancelToken to repository', () async {
      final token = MockAppCancellationToken();
      final tParamsWithToken = CreateInformationParams(
        title: 'Pengumuman Penting',
        session: tSessionAdmin,
        cancelToken: token,
      );
      when(
        () => mockRepository.createInformation(any()),
      ).thenAnswer((_) async => const Right(tResultEntity));

      final result = await useCase(tParamsWithToken);

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.createInformation(
          tParamsWithToken.toRepositoryData(),
        ),
      ).called(1);
    });

    test('returns failure when repository fails', () async {
      const tFailure = ServerFailure('Koneksi database bermasalah.');
      when(
        () => mockRepository.createInformation(any()),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await useCase(tParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, equals(tFailure)),
        (_) => fail('Should be Left'),
      );
    });
  });
}
