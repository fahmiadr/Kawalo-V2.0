import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCacheWiper extends Mock implements CacheWiper {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;
  late MockCacheWiper mockCacheWiper;

  const tUser = UserEntity(
    id: 'user_1',
    name: 'Test User',
    email: 'test@example.com',
    groups: [],
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    mockCacheWiper = MockCacheWiper();
    useCase = LoginUseCase(mockRepository, cacheWiper: mockCacheWiper);
  });

  test('should return UserEntity and wipe cache on successful login', () async {
    when(
      () => mockRepository.login(
        email: 'test@example.com',
        password: 'password123',
      ),
    ).thenAnswer((_) async => const Right(tUser));
    when(() => mockCacheWiper.wipeAll()).thenAnswer((_) async {});

    final result = await useCase(
      const LoginParams(email: 'test@example.com', password: 'password123'),
    );

    expect(result, const Right<Failure, UserEntity>(tUser));
    verify(() => mockCacheWiper.wipeAll()).called(1);
    verify(
      () => mockRepository.login(
        email: 'test@example.com',
        password: 'password123',
      ),
    ).called(1);
  });

  test('should return Failure on repository login failure', () async {
    const failure = ServerFailure('Invalid credentials');
    when(
      () => mockRepository.login(
        email: 'test@example.com',
        password: 'password123',
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      const LoginParams(email: 'test@example.com', password: 'password123'),
    );

    expect(result, const Left<Failure, UserEntity>(failure));
    verifyNever(() => mockCacheWiper.wipeAll());
  });
}
