import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_guests/get_guests_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late GetGuestsUseCase useCase;
  late MockGuestRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const GetGuestsParams());
  });

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = GetGuestsUseCase(mockRepository);
  });

  const tGuest = GuestItemEntity(
    id: 'guest_1',
    guestNumber: 'B 1234 CD',
    guestCategory: 'Tamu',
    guestDestination: 'Blok A1',
    guestToUserName: 'John Doe',
    guestPurpose: 'Kunjungan',
    guestDt: 'Hari ini, 10.00',
  );
  const tGuestList = [tGuest];
  const tGuestResult = GuestResult(items: tGuestList);

  test(
    'should return list of guests when repository call is successful',
    () async {
      const tParams = GetGuestsParams(search: 'John');
      when(
        () => mockRepository.getGuests(any()),
      ).thenAnswer((_) async => const Right(tGuestResult));

      final result = await useCase(tParams);

      expect(result, const Right<Failure, GuestResult>(tGuestResult));
      verify(() => mockRepository.getGuests(tParams)).called(1);
    },
  );

  test('should return Failure when repository call fails', () async {
    const tFailure = ServerFailure('Gagal memuat data');
    const tParams = GetGuestsParams();
    when(
      () => mockRepository.getGuests(any()),
    ).thenAnswer((_) async => const Left(tFailure));

    final result = await useCase(tParams);

    expect(result, const Left<Failure, GuestResult>(tFailure));
    verify(() => mockRepository.getGuests(tParams)).called(1);
  });
}
