import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  const tUser = UserEntity(
    id: 'user_1',
    email: 'admin@kawalo.co.id',
    name: 'Admin',
    groups: [],
  );

  test(
    'should return UserEntity from repository when user is logged in',
    () async {
      when(
        () => mockRepository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await useCase(const NoParams());

      expect(result, const Right<Failure, UserEntity?>(tUser));
      verify(() => mockRepository.getCurrentUser()).called(1);
    },
  );
}
