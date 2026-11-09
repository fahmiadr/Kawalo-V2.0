import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late GetMasterGuestTypesUseCase useCase;
  late MockGuestRepository mockRepository;

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = GetMasterGuestTypesUseCase(mockRepository);
  });

  const tTypes = [
    MasterGuestTypeEntity(id: '1', uid: 'GT-001', name: 'TAMU'),
    MasterGuestTypeEntity(id: '2', uid: 'GT-002', name: 'KURIR'),
  ];

  test('should return list of MasterGuestTypeEntity when successful', () async {
    when(
      () => mockRepository.getMasterGuestTypes(
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const Right<Failure, List<MasterGuestTypeEntity>>(tTypes),
    );

    final result = await useCase(const GetMasterGuestTypesParams());

    expect(result, const Right<Failure, List<MasterGuestTypeEntity>>(tTypes));
    verify(
      () => mockRepository.getMasterGuestTypes(
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);
  });

  test('should return Failure when repository call fails', () async {
    const tFailure = ServerFailure('Gagal memuat master tipe tamu');
    when(
      () => mockRepository.getMasterGuestTypes(
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const Left<Failure, List<MasterGuestTypeEntity>>(tFailure),
    );

    final result = await useCase(const GetMasterGuestTypesParams());

    expect(result, const Left<Failure, List<MasterGuestTypeEntity>>(tFailure));
  });

  test('GetMasterGuestTypesParams supports value equality', () {
    expect(
      const GetMasterGuestTypesParams(),
      equals(const GetMasterGuestTypesParams()),
    );
  });
}
