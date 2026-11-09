import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_params.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_guests/get_guests_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGuestsUseCase extends Mock implements GetGuestsUseCase {}

class MockDeleteGuestUseCase extends Mock implements DeleteGuestUseCase {}

class MockDeleteBatchGuestUseCase extends Mock
    implements DeleteBatchGuestUseCase {}

class MockCheckoutGuestUseCase extends Mock implements CheckoutGuestUseCase {}

class MockGetGroupMembersUseCase extends Mock
    implements GetGroupMembersUseCase {}

void main() {
  late GuestCubit cubit;
  late MockGetGuestsUseCase mockGetGuestsUseCase;
  late MockDeleteGuestUseCase mockDeleteGuestUseCase;
  late MockDeleteBatchGuestUseCase mockDeleteBatchGuestUseCase;

  setUpAll(() {
    const dummySession = AuthSessionEntity(
      userId: '1',
      email: 'admin@example.com',
      name: 'Admin',
      role: 'ADMIN',
      allowAdmin: true,
      allowPatrol: true,
      allowMonPatrol: true,
    );
    const dummyGuest = GuestItemEntity(id: 'guest_1');
    registerFallbackValue(const GetGuestsParams());
    registerFallbackValue(const GetGroupMembersParams());
    registerFallbackValue(
      const DeleteGuestParams(id: '1', session: dummySession, item: dummyGuest),
    );
    registerFallbackValue(
      const CheckoutGuestParams(
        id: '1',
        session: dummySession,
        item: dummyGuest,
      ),
    );
    registerFallbackValue(
      const DeleteBatchGuestParams(
        ids: ['1'],
        session: dummySession,
        items: [dummyGuest],
      ),
    );
  });

  setUp(() {
    mockGetGuestsUseCase = MockGetGuestsUseCase();
    mockDeleteGuestUseCase = MockDeleteGuestUseCase();
    mockDeleteBatchGuestUseCase = MockDeleteBatchGuestUseCase();
    cubit = GuestCubit(
      getGuestsUseCase: mockGetGuestsUseCase,
      deleteGuestUseCase: mockDeleteGuestUseCase,
      deleteBatchGuestUseCase: mockDeleteBatchGuestUseCase,
    );
  });

  tearDown(() {
    cubit.close();
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
  const tSession = AuthSessionEntity(
    userId: '1',
    email: 'admin@example.com',
    name: 'Admin',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );
  const tGuestList = [tGuest];
  const tResult = GuestResult(items: tGuestList);
  const tCachedResult = GuestResult(items: tGuestList, isFromCache: true);

  test('initial state should be GuestInitial', () {
    expect(cubit.state, const GuestInitial());
    expect(cubit.currentGreeting, isEmpty);
  });

  test('initial state contains initialGreeting when provided', () {
    final customCubit = GuestCubit(
      getGuestsUseCase: mockGetGuestsUseCase,
      deleteGuestUseCase: mockDeleteGuestUseCase,
      deleteBatchGuestUseCase: mockDeleteBatchGuestUseCase,
      initialGreeting: 'Diperbarui Hari ini, 15.20',
    );
    expect(
      customCubit.state,
      const GuestInitial(lastSync: 'Diperbarui Hari ini, 15.20'),
    );
    expect(customCubit.currentGreeting, 'Diperbarui Hari ini, 15.20');
    customCubit.close();
  });

  group('fetchGuests', () {
    blocTest<GuestCubit, GuestState>(
      'emits [GuestLoading, GuestLoaded] when successful',
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchGuests(),
      expect: () => [
        const GuestLoading(),
        isA<GuestLoaded>()
            .having((s) => s.guests.length, 'guests length', 1)
            .having(
              (s) => s.lastSync.startsWith('Diperbarui'),
              'has updated lastSync',
              isTrue,
            )
            .having((s) => s.isFromCache, 'isFromCache', false),
      ],
      verify: (_) {
        verify(() => mockGetGuestsUseCase(any())).called(1);
      },
    );

    blocTest<GuestCubit, GuestState>(
      'emits [GuestLoading, GuestLoaded] with isFromCache true when '
      'serving cache',
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Right(tCachedResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchGuests(),
      expect: () => [
        const GuestLoading(),
        isA<GuestLoaded>()
            .having((s) => s.guests.length, 'guests length', 1)
            .having((s) => s.isFromCache, 'isFromCache', true),
      ],
    );

    blocTest<GuestCubit, GuestState>(
      'emits [GuestLoading, GuestError] when call fails',
      build: () {
        when(() => mockGetGuestsUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal memuat data tamu')),
        );
        return cubit;
      },
      act: (cubit) => cubit.fetchGuests(),
      expect: () => [
        const GuestLoading(),
        isA<GuestError>().having(
          (e) => e.message,
          'message',
          'Gagal memuat data tamu',
        ),
      ],
    );
  });

  group('refreshGuests', () {
    blocTest<GuestCubit, GuestState>(
      'emits [GuestLoaded] with updated lastSync on pull to refresh',
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.refreshGuests(),
      expect: () => [
        isA<GuestLoaded>()
            .having((s) => s.guests.length, 'guests length', 1)
            .having(
              (s) => s.lastSync.startsWith('Diperbarui'),
              'has updated lastSync',
              isTrue,
            ),
      ],
    );

    blocTest<GuestCubit, GuestState>(
      'emits GuestLoaded with empty items when cache returns empty on '
      'refresh and does not retain previous guests',
      seed: () => const GuestLoaded(
        guests: tGuestList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      build: () {
        when(() => mockGetGuestsUseCase(any())).thenAnswer(
          (_) async => const Right(GuestResult(items: [], isFromCache: true)),
        );
        return cubit;
      },
      act: (cubit) => cubit.refreshGuests(),
      expect: () => [
        isA<GuestLoaded>()
            .having((s) => s.guests, 'guests', isEmpty)
            .having((s) => s.isFromCache, 'isFromCache', isTrue),
      ],
    );

    blocTest<GuestCubit, GuestState>(
      'emits [GuestError] with cached guests when refresh fails',
      seed: () => const GuestLoaded(
        guests: tGuestList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      build: () {
        when(() => mockGetGuestsUseCase(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Koneksi terputus')),
        );
        return cubit;
      },
      act: (cubit) => cubit.refreshGuests(),
      expect: () => [
        isA<GuestError>()
            .having((e) => e.message, 'message', 'Koneksi terputus')
            .having((e) => e.cachedGuests, 'cachedGuests', tGuestList)
            .having(
              (e) => e.isFromCache,
              'isFromCache is true when cached',
              true,
            ),
      ],
    );

    blocTest<GuestCubit, GuestState>(
      'clears cachedGuests when fetchGuests with new query fails',
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      seed: () => const GuestLoaded(
        guests: tGuestList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.fetchGuests(search: 'Budi'),
      expect: () => [
        isA<GuestError>()
            .having((e) => e.message, 'message', 'Server Error')
            .having((e) => e.cachedGuests, 'cachedGuests', isEmpty),
      ],
    );

    blocTest<GuestCubit, GuestState>(
      'emits GuestError with empty cachedGuests when custom filter fails',
      seed: () => GuestLoaded(
        guests: tGuestList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
      ),
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Timeout')));
        return cubit;
      },
      act: (cubit) => cubit.fetchGuests(
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
      ),
      expect: () => [
        isA<GuestError>()
            .having((e) => e.message, 'message', 'Timeout')
            .having(
              (e) => e.filterPeriod,
              'filterPeriod',
              AppDateFilterPeriod.custom,
            )
            .having((e) => e.startDate, 'startDate', DateTime(2026, 9))
            .having((e) => e.endDate, 'endDate', DateTime(2026, 9, 5)),
      ],
    );

    blocTest<GuestCubit, GuestState>(
      'resetFilters clears search, creator, and date filter '
      'and resets to today',
      seed: () => GuestLoaded(
        guests: tGuestList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
        searchQuery: 'cari',
      ),
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.resetFilters(),
      verify: (_) {
        verify(
          () => mockGetGuestsUseCase(
            any(
              that: isA<GetGuestsParams>()
                  .having((p) => p.search, 'search', isNull)
                  .having((p) => p.startDate, 'startDate', isNotNull)
                  .having((p) => p.endDate, 'endDate', isNotNull),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as GuestLoaded;
        expect(loaded.searchQuery, isNull);
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
        expect(loaded.startDate, isNull);
        expect(loaded.endDate, isNull);
      },
    );

    blocTest<GuestCubit, GuestState>(
      'resetDateFilter clears date filter while preserving search query',
      seed: () => GuestLoaded(
        guests: tGuestList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
        searchQuery: 'cari',
        filterCreatorEmail: 'satpam.budi@kawalo.id',
      ),
      build: () {
        when(
          () => mockGetGuestsUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.resetDateFilter(),
      verify: (_) {
        verify(
          () => mockGetGuestsUseCase(
            any(
              that: isA<GetGuestsParams>()
                  .having((p) => p.search, 'search', 'cari')
                  .having(
                    (p) => p.createdBy,
                    'createdBy',
                    'satpam.budi@kawalo.id',
                  )
                  .having((p) => p.startDate, 'startDate', isNotNull)
                  .having((p) => p.endDate, 'endDate', isNotNull),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as GuestLoaded;
        expect(loaded.searchQuery, 'cari');
        expect(loaded.filterCreatorEmail, 'satpam.budi@kawalo.id');
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
        expect(loaded.startDate, isNull);
        expect(loaded.endDate, isNull);
      },
    );
  });

  group('GuestLoaded filter helper getters', () {
    test('searchQuery getter returns assigned search value or null', () {
      const stateDefault = GuestLoaded(guests: [], lastSync: 'Waktu');
      expect(stateDefault.searchQuery, isNull);

      final stateWithSearch = stateDefault.copyWith(searchQuery: 'john');
      expect(stateWithSearch.searchQuery, 'john');
    });

    test(
      'hasActiveDateFilter bernilai true jika filter period bukan today atau '
      'ada custom date',
      () {
        const stateDefault = GuestLoaded(guests: [], lastSync: 'Waktu');
        expect(stateDefault.hasActiveDateFilter, isFalse);

        final stateWeek = stateDefault.copyWith(
          filterPeriod: AppDateFilterPeriod.thisWeek,
        );
        expect(stateWeek.hasActiveDateFilter, isTrue);

        final stateCustom = stateDefault.copyWith(
          filterPeriod: AppDateFilterPeriod.custom,
          startDate: DateTime(2026),
        );
        expect(stateCustom.hasActiveDateFilter, isTrue);
      },
    );

    test('hasActiveFilter mendeteksi kombinasi pencarian atau tanggal', () {
      const stateDefault = GuestLoaded(guests: [], lastSync: 'Waktu');
      expect(stateDefault.hasActiveFilter, isFalse);

      expect(
        stateDefault.copyWith(searchQuery: 'tamu').hasActiveFilter,
        isTrue,
      );
    });
  });

  group('RequestSequenceGuard in GuestCubit', () {
    test('mengabaikan respons dari request lama yang datang terlambat '
        '(out-of-order)', () async {
      const guestA = [
        GuestItemEntity(
          id: 'guest_A',
          guestNumber: 'B 1234 CD',
          guestCategory: 'Tamu',
          guestDestination: 'Blok A',
          guestToUserName: 'John Doe',
          guestPurpose: 'Kunjungan',
          guestDt: 'Hari ini, 10.00',
        ),
      ];
      const guestB = [
        GuestItemEntity(
          id: 'guest_B',
          guestNumber: 'B 1234 CD',
          guestCategory: 'Tamu',
          guestDestination: 'Blok B',
          guestToUserName: 'John Doe',
          guestPurpose: 'Kunjungan',
          guestDt: 'Hari ini, 10.00',
        ),
      ];

      var firstCallCompleted = false;

      when(
        () => mockGetGuestsUseCase(
          any(that: predicate<GetGuestsParams>((p) => p.search == 'first')),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        firstCallCompleted = true;
        return const Right(GuestResult(items: guestA));
      });

      when(
        () => mockGetGuestsUseCase(
          any(that: predicate<GetGuestsParams>((p) => p.search == 'second')),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Right(GuestResult(items: guestB));
      });

      // Panggil search 'first' lalu segera panggil 'second'
      final futureFirst = cubit.fetchGuests(search: 'first');
      final futureSecond = cubit.fetchGuests(search: 'second');

      await Future.wait([futureFirst, futureSecond]);

      expect(firstCallCompleted, isTrue);
      // State akhir HARUS guestB (karena second adalah yang terbaru),
      // bukan tertimpa oleh guestA!
      expect(cubit.state, isA<GuestLoaded>());
      final loaded = cubit.state as GuestLoaded;
      expect(loaded.searchQuery, 'second');
      expect(loaded.guests.first.id, 'guest_B');
    });
  });

  group('deleteGuest', () {
    test('removes item from GuestLoaded state on success', () async {
      when(
        () => mockDeleteGuestUseCase(any()),
      ).thenAnswer((_) async => const Right(null));

      cubit.emit(const GuestLoaded(guests: [tGuest], lastSync: '10:00'));

      final result = await cubit.deleteGuest(tGuest, session: tSession);

      expect(result.isRight(), isTrue);
      expect(cubit.state, isA<GuestLoaded>());
      final loaded = cubit.state as GuestLoaded;
      expect(loaded.guests, isEmpty);
    });

    test('does not mutate GuestLoaded state on failure', () async {
      when(() => mockDeleteGuestUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal menghapus data tamu.')),
      );

      cubit.emit(const GuestLoaded(guests: [tGuest], lastSync: '10:00'));

      final result = await cubit.deleteGuest(tGuest, session: tSession);

      expect(result.isLeft(), isTrue);
      final loaded = cubit.state as GuestLoaded;
      expect(loaded.guests.length, 1);
    });
  });

  group('deleteMultipleGuests', () {
    const tDeleteResult = DeleteBatchResult(deletedCount: 1);

    test('removes items from GuestLoaded state on success', () async {
      when(
        () => mockDeleteBatchGuestUseCase(any()),
      ).thenAnswer((_) async => const Right(tDeleteResult));

      const guest2 = GuestItemEntity(id: 'guest_2', guestName: 'Guest 2');
      cubit.emit(
        const GuestLoaded(guests: [tGuest, guest2], lastSync: '10:00'),
      );

      final result = await cubit.deleteMultipleGuests({
        'guest_1',
      }, session: tSession);

      expect(result.isRight(), isTrue);
      expect(cubit.state, isA<GuestLoaded>());
      final loaded = cubit.state as GuestLoaded;
      expect(loaded.guests.length, 1);
      expect(loaded.guests.first.id, 'guest_2');
    });

    test('does not mutate GuestLoaded state on failure', () async {
      when(() => mockDeleteBatchGuestUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal menghapus data tamu.')),
      );

      cubit.emit(const GuestLoaded(guests: [tGuest], lastSync: '10:00'));

      final result = await cubit.deleteMultipleGuests({
        'guest_1',
      }, session: tSession);

      expect(result.isLeft(), isTrue);
      final loaded = cubit.state as GuestLoaded;
      expect(loaded.guests.length, 1);
    });
  });

  group('changeCreatorFilter', () {
    const tGuestOther = GuestItemEntity(
      id: 'guest_2',
      guestName: 'Guest 2',
      guestCreatorEmail: 'other@kawalo.id',
    );

    test('changes creator filter and fetches server-filtered guests', () async {
      when(() => mockGetGuestsUseCase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetGuestsParams;
        if (params.createdBy == 'satpam@kawalo.id') {
          return const Right(GuestResult(items: [tGuest]));
        }
        return const Right(GuestResult(items: [tGuest, tGuestOther]));
      });

      cubit.emit(
        const GuestLoaded(guests: [tGuest, tGuestOther], lastSync: '10:00'),
      );

      final initialLoaded = cubit.state as GuestLoaded;
      expect(initialLoaded.displayedGuests.length, 2);

      await cubit.changeCreatorFilter(
        email: 'satpam@kawalo.id',
        name: 'Budi Santoso',
      );

      final mineLoaded = cubit.state as GuestLoaded;
      expect(mineLoaded.filterCreatorEmail, 'satpam@kawalo.id');
      expect(mineLoaded.filterCreatorName, 'Budi Santoso');
      expect(mineLoaded.hasActiveCreatorFilter, isTrue);
      expect(mineLoaded.displayedGuests.length, 1);
      expect(mineLoaded.displayedGuests.first.id, 'guest_1');
      verify(
        () => mockGetGuestsUseCase(
          any(
            that: isA<GetGuestsParams>().having(
              (p) => p.createdBy,
              'createdBy',
              'satpam@kawalo.id',
            ),
          ),
        ),
      ).called(1);

      await cubit.changeCreatorFilter();

      final allLoaded = cubit.state as GuestLoaded;
      expect(allLoaded.filterCreatorEmail, isNull);
      expect(allLoaded.filterCreatorName, isNull);
      expect(allLoaded.hasActiveCreatorFilter, isFalse);
      expect(allLoaded.displayedGuests.length, 2);
      verify(
        () => mockGetGuestsUseCase(
          any(
            that: isA<GetGuestsParams>().having(
              (p) => p.createdBy,
              'createdBy',
              isNull,
            ),
          ),
        ),
      ).called(1);
    });

    group('loadGroupMembers', () {
      late MockGetGroupMembersUseCase mockGetGroupMembersUseCase;

      setUp(() {
        mockGetGroupMembersUseCase = MockGetGroupMembersUseCase();
      });

      test('returns remote group members when use case succeeds', () async {
        const tMembers = [
          GroupMemberEntity(email: 'member1@kawalo.id', name: 'Member One'),
          GroupMemberEntity(email: 'member2@kawalo.id', name: 'Member Two'),
        ];

        when(
          () => mockGetGroupMembersUseCase(any()),
        ).thenAnswer((_) async => const Right(tMembers));

        final cubitWithMembers = GuestCubit(
          getGuestsUseCase: mockGetGuestsUseCase,
          deleteGuestUseCase: mockDeleteGuestUseCase,
          deleteBatchGuestUseCase: mockDeleteBatchGuestUseCase,
          getGroupMembersUseCase: mockGetGroupMembersUseCase,
        );

        final result = await cubitWithMembers.loadGroupMembers();

        expect(result, const Right<Failure, List<GroupMemberEntity>>(tMembers));
        verify(() => mockGetGroupMembersUseCase(any())).called(1);
        await cubitWithMembers.close();
      });

      test('returns failure when remote fetch fails', () async {
        const tFailure = ServerFailure('Server Error');
        when(
          () => mockGetGroupMembersUseCase(any()),
        ).thenAnswer((_) async => const Left(tFailure));

        final cubitWithMembers = GuestCubit(
          getGuestsUseCase: mockGetGuestsUseCase,
          deleteGuestUseCase: mockDeleteGuestUseCase,
          deleteBatchGuestUseCase: mockDeleteBatchGuestUseCase,
          getGroupMembersUseCase: mockGetGroupMembersUseCase,
        );

        final result = await cubitWithMembers.loadGroupMembers();

        expect(result, const Left<Failure, List<GroupMemberEntity>>(tFailure));
        verify(() => mockGetGroupMembersUseCase(any())).called(1);
        await cubitWithMembers.close();
      });

      test('returns failure when getGroupMembersUseCase is null', () async {
        final result = await cubit.loadGroupMembers();

        expect(
          result,
          const Left<Failure, List<GroupMemberEntity>>(
            ServerFailure('Layanan anggota grup tidak tersedia.'),
          ),
        );
      });
    });

    group('checkoutGuest', () {
      late MockCheckoutGuestUseCase mockCheckoutGuestUseCase;
      const tGuest = GuestItemEntity(id: '1', guestName: 'Budi');
      const tUpdatedGuest = GuestItemEntity(
        id: '1',
        guestName: 'Budi',
        guestOutDt: '2026-11-02T12:00:00.000Z',
      );
      const tSession = AuthSessionEntity(
        userId: '1',
        email: 'guard@kawalo.id',
        name: 'Guard',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      setUp(() {
        mockCheckoutGuestUseCase = MockCheckoutGuestUseCase();
      });

      test('returns ServerFailure when checkoutGuestUseCase is null', () async {
        final result = await cubit.checkoutGuest(tGuest, session: tSession);

        expect(
          result,
          const Left<Failure, GuestItemEntity>(
            ServerFailure('Layanan checkout tamu tidak tersedia.'),
          ),
        );
      });

      test('delegates to checkoutGuestUseCase and updates item in '
          'GuestLoaded state', () async {
        when(
          () => mockCheckoutGuestUseCase(any()),
        ).thenAnswer((_) async => const Right(tUpdatedGuest));

        final cubitWithCheckout =
            GuestCubit(
              getGuestsUseCase: mockGetGuestsUseCase,
              deleteGuestUseCase: mockDeleteGuestUseCase,
              deleteBatchGuestUseCase: mockDeleteBatchGuestUseCase,
              checkoutGuestUseCase: mockCheckoutGuestUseCase,
            )..emit(
              const GuestLoaded(
                guests: [tGuest],
                lastSync: 'Sync',
                hasMore: false,
              ),
            );

        final result = await cubitWithCheckout.checkoutGuest(
          tGuest,
          session: tSession,
          qrUid: 'QR-1',
        );

        expect(result, const Right<Failure, GuestItemEntity>(tUpdatedGuest));
        verify(
          () => mockCheckoutGuestUseCase(
            const CheckoutGuestParams(
              id: '1',
              session: tSession,
              item: tGuest,
              qrUid: 'QR-1',
            ),
          ),
        ).called(1);

        expect(
          (cubitWithCheckout.state as GuestLoaded).guests.first.isExited,
          isTrue,
        );
        await cubitWithCheckout.close();
      });

      test('does not modify state when checkoutGuestUseCase fails', () async {
        const tFailure = ValidationFailure('Invalid ID');
        when(
          () => mockCheckoutGuestUseCase(any()),
        ).thenAnswer((_) async => const Left(tFailure));

        final cubitWithCheckout =
            GuestCubit(
              getGuestsUseCase: mockGetGuestsUseCase,
              deleteGuestUseCase: mockDeleteGuestUseCase,
              deleteBatchGuestUseCase: mockDeleteBatchGuestUseCase,
              checkoutGuestUseCase: mockCheckoutGuestUseCase,
            )..emit(
              const GuestLoaded(
                guests: [tGuest],
                lastSync: 'Sync',
                hasMore: false,
              ),
            );

        final result = await cubitWithCheckout.checkoutGuest(
          tGuest,
          session: tSession,
        );

        expect(result, const Left<Failure, GuestItemEntity>(tFailure));
        expect(
          (cubitWithCheckout.state as GuestLoaded).guests.first.isExited,
          isFalse,
        );
        await cubitWithCheckout.close();
      });
    });
  });
}
