import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements GuestRepository {}

class _MockDelete extends Mock implements DeleteGuestUseCase {}

class _MockDeleteBatch extends Mock implements DeleteBatchGuestUseCase {}

class _MockAcknowledge extends Mock implements AcknowledgeGuestUseCase {}

void main() {
  const waiting = GuestItemEntity(id: '1', guestName: 'Budi');
  const confirmed = GuestItemEntity(
    id: '1',
    guestName: 'Budi',
    guestAckDt: '2026-11-02T10:00:00.000Z',
  );
  const session = AuthSessionEntity(
    userId: '1',
    email: 'guard@kawalo.id',
    name: 'Guard',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  late _MockRepo repo;
  late _MockAcknowledge acknowledge;

  setUpAll(() {
    registerFallbackValue(const GetGuestsParams());
    registerFallbackValue(
      const AcknowledgeGuestParams(id: '1', session: session, item: waiting),
    );
  });

  setUp(() {
    repo = _MockRepo();
    acknowledge = _MockAcknowledge();
    when(
      () => repo.getGuests(any()),
    ).thenAnswer((_) async => const Right(GuestResult(items: [waiting])));
  });

  GuestCubit build({bool withAcknowledge = true}) => GuestCubit(
    syncStorageService: SyncStorageService(),
    guestRepository: repo,
    deleteGuestUseCase: _MockDelete(),
    deleteBatchGuestUseCase: _MockDeleteBatch(),
    acknowledgeGuestUseCase: withAcknowledge ? acknowledge : null,
  );

  group('acknowledgeGuest', () {
    test('fails when the use case is not wired', () async {
      final cubit = build(withAcknowledge: false);

      final result = await cubit.acknowledgeGuest(waiting, session: session);

      expect(
        result,
        const Left<Failure, GuestItemEntity>(
          ServerFailure('Layanan konfirmasi tamu tidak tersedia.'),
        ),
      );
      await cubit.close();
    });

    test('replaces the item in the loaded list on success', () async {
      when(
        () => acknowledge(any()),
      ).thenAnswer((_) async => const Right(confirmed));
      final cubit = build()
        ..emit(
          const GuestLoaded(guests: [waiting], lastSync: 'x', hasMore: false),
        );

      final result = await cubit.acknowledgeGuest(
        waiting,
        session: session,
        qrUid: 'QR-1',
      );

      expect(result, const Right<Failure, GuestItemEntity>(confirmed));
      verify(
        () => acknowledge(
          const AcknowledgeGuestParams(
            id: '1',
            session: session,
            item: waiting,
            qrUid: 'QR-1',
          ),
        ),
      ).called(1);
      expect((cubit.state as GuestLoaded).guests.single.isAcknowledged, isTrue);
      await cubit.close();
    });

    test('keeps the list untouched on failure', () async {
      when(
        () => acknowledge(any()),
      ).thenAnswer((_) async => const Left(ForbiddenFailure('Tidak berhak.')));
      final cubit = build()
        ..emit(
          const GuestLoaded(guests: [waiting], lastSync: 'x', hasMore: false),
        );

      final result = await cubit.acknowledgeGuest(waiting, session: session);

      expect(result.isLeft(), isTrue);
      expect(
        (cubit.state as GuestLoaded).guests.single.isAcknowledged,
        isFalse,
      );
      await cubit.close();
    });
  });

  group('"Masih di lokasi" filter (is_active)', () {
    test('changeActiveFilter sends is_active and exposes the state', () async {
      final cubit = build();

      await cubit.changeActiveFilter(isActive: true);

      final loaded = cubit.state as GuestLoaded;
      expect(loaded.filterIsActive, isTrue);
      expect(loaded.hasActiveStatusFilter, isTrue);
      expect(loaded.hasActiveFilter, isTrue);
      verify(
        () => repo.getGuests(
          any(
            that: isA<GetGuestsParams>().having((p) => p.isActive, 'a', true),
          ),
        ),
      ).called(1);
      await cubit.close();
    });

    test(
      'the filter survives other fetches and clears on toggle off',
      () async {
        final cubit = build();
        await cubit.changeActiveFilter(isActive: true);

        await cubit.fetchGuests(search: 'budi');
        expect((cubit.state as GuestLoaded).filterIsActive, isTrue);

        await cubit.changeActiveFilter();
        final loaded = cubit.state as GuestLoaded;
        expect(loaded.filterIsActive, isNull);
        expect(loaded.hasActiveStatusFilter, isFalse);
        await cubit.close();
      },
    );

    test('loadMoreGuests keeps the active filter', () async {
      final cubit = build();
      await cubit.changeActiveFilter(isActive: true);
      clearInteractions(repo);

      await cubit.loadMoreGuests();

      verifyNever(
        () => repo.getGuests(
          any(
            that: isA<GetGuestsParams>().having((p) => p.isActive, 'a', isNull),
          ),
        ),
      );
      await cubit.close();
    });

    test('resetFilters clears the status filter', () async {
      final cubit = build();
      await cubit.changeActiveFilter(isActive: true);

      await cubit.resetFilters();

      expect((cubit.state as GuestLoaded).filterIsActive, isNull);
      await cubit.close();
    });
  });
}
