import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCacheWiper extends Mock implements CacheWiper {}

void main() {
  late SwitchGroupUseCase useCase;
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
    useCase = SwitchGroupUseCase(mockRepository, cacheWiper: mockCacheWiper);
  });

  test(
    'should return UserEntity and wipe cache on switchGroup success',
    () async {
      when(
        () => mockRepository.switchGroup(groupUid: 'group_abc'),
      ).thenAnswer((_) async => const Right(tUser));
      when(() => mockCacheWiper.wipeAll()).thenAnswer((_) async {});

      final result = await useCase(
        const SwitchGroupParams(groupUid: 'group_abc'),
      );

      expect(result, const Right<Failure, UserEntity>(tUser));
      verify(() => mockCacheWiper.wipeAll()).called(1);
      verify(() => mockRepository.switchGroup(groupUid: 'group_abc')).called(1);
    },
  );

  test('should return Failure on switchGroup error', () async {
    const failure = ServerFailure('Switch group failed');
    when(
      () => mockRepository.switchGroup(groupUid: 'group_abc'),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      const SwitchGroupParams(groupUid: 'group_abc'),
    );

    expect(result, const Left<Failure, UserEntity>(failure));
    verifyNever(() => mockCacheWiper.wipeAll());
  });
}
