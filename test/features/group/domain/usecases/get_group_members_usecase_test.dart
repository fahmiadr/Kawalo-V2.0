import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_params.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late MockGroupRepository mockRepository;
  late GetGroupMembersUseCase useCase;

  setUp(() {
    mockRepository = MockGroupRepository();
    useCase = GetGroupMembersUseCase(mockRepository);
  });

  const tMembers = [
    GroupMemberEntity(
      email: 'user1@kawalo.id',
      name: 'User Satu',
      profilePic: 'https://example.com/pic1.jpg',
    ),
    GroupMemberEntity(
      email: 'user2@kawalo.id',
      name: 'User Dua',
    ),
  ];

  test('should call repository.getMembers and return list of entities',
      () async {
    when(
      () => mockRepository.getMembers(
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const Right<Failure, List<GroupMemberEntity>>(tMembers),
    );

    final cancelToken = MockAppCancellationToken();
    final result = await useCase(
      GetGroupMembersParams(cancelToken: cancelToken),
    );

    expect(result, const Right<Failure, List<GroupMemberEntity>>(tMembers));
    verify(() => mockRepository.getMembers(cancelToken: cancelToken)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when repository call fails', () async {
    const tFailure = ServerFailure('Gagal memuat anggota grup');
    when(
      () => mockRepository.getMembers(
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const Left<Failure, List<GroupMemberEntity>>(tFailure),
    );

    final result = await useCase(const GetGroupMembersParams());

    expect(result, const Left<Failure, List<GroupMemberEntity>>(tFailure));
    verify(() => mockRepository.getMembers()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
