import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/get_information/get_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_result.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetInformationUseCase extends Mock implements GetInformationUseCase {}

class MockDeleteInformationUseCase extends Mock
    implements DeleteInformationUseCase {}

class MockDeleteBatchInformationUseCase extends Mock
    implements DeleteBatchInformationUseCase {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late InformationCubit cubit;
  late MockGetInformationUseCase mockGetInformationUseCase;
  late MockDeleteInformationUseCase mockDeleteInformationUseCase;
  late MockDeleteBatchInformationUseCase mockDeleteBatchInformationUseCase;

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
    const dummyItem = InformationItemEntity(id: '1', photos: []);
    registerFallbackValue(const GetInformationParams());
    registerFallbackValue(
      const DeleteInformationParams(
        id: '1',
        session: dummySession,
        item: dummyItem,
      ),
    );
    registerFallbackValue(
      const DeleteBatchInformationParams(
        ids: ['1'],
        session: dummySession,
        items: [dummyItem],
      ),
    );
  });

  setUp(() {
    mockGetInformationUseCase = MockGetInformationUseCase();
    mockDeleteInformationUseCase = MockDeleteInformationUseCase();
    mockDeleteBatchInformationUseCase = MockDeleteBatchInformationUseCase();
    cubit = InformationCubit(
      getInformationUseCase: mockGetInformationUseCase,
      deleteInformationUseCase: mockDeleteInformationUseCase,
      deleteBatchInformationUseCase: mockDeleteBatchInformationUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tItem = InformationItemEntity(
    id: '1',
    photos: [],
    title: 'Pemeriksaan Pos Jaga',
    text: 'Aman terkendali.',
    userEmail: 'satpam@kawalo.id',
    userName: 'Budi Santoso',
    feedDt: '09 Sep 2026 14:20',
    feedType: 'GENERAL',
    groupName: 'JKN Veranda',
    glat: -6.2,
    glong: 106.816666,
  );
  const tSession = AuthSessionEntity(
    userId: '1',
    email: 'satpam@kawalo.id',
    name: 'Budi Santoso',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );
  const tList = <InformationItemEntity>[tItem];
  const tResult = InformationResult(items: tList);
  const tCachedResult = InformationResult(items: tList, isFromCache: true);

  test('initial state should be InformationInitial', () {
    expect(cubit.state, const InformationInitial());
  });

  group('fetchInformation', () {
    blocTest<InformationCubit, InformationState>(
      'emits [InformationLoading, InformationLoaded] when successful',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchInformation(),
      expect: () => [
        const InformationLoading(),
        isA<InformationLoaded>()
            .having((s) => s.information.length, 'items count', 1)
            .having(
              (s) => s.filterPeriod,
              'filterPeriod',
              AppDateFilterPeriod.today,
            )
            .having((s) => s.hasMore, 'hasMore', false)
            .having((s) => s.isFromCache, 'isFromCache', false),
      ],
    );

    blocTest<InformationCubit, InformationState>(
      'emits [InformationLoading, InformationLoaded] with isFromCache true '
      'when serving cached fallback',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tCachedResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchInformation(),
      expect: () => [
        const InformationLoading(),
        isA<InformationLoaded>()
            .having((s) => s.information.length, 'items count', 1)
            .having((s) => s.isFromCache, 'isFromCache', true),
      ],
    );

    blocTest<InformationCubit, InformationState>(
      'emits [InformationLoading, InformationError] on failure',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('API Error')));
        return cubit;
      },
      act: (cubit) => cubit.fetchInformation(),
      expect: () => [
        const InformationLoading(),
        isA<InformationError>().having(
          (s) => s.message,
          'message',
          'API Error',
        ),
      ],
    );

    blocTest<InformationCubit, InformationState>(
      'normalizes empty search to null and sets searchQuery to null',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchInformation(search: ''),
      verify: (_) {
        verify(
          () => mockGetInformationUseCase(
            any(
              that: isA<GetInformationParams>().having(
                (p) => p.search,
                'search',
                isNull,
              ),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as InformationLoaded;
        expect(loaded.searchQuery, isNull);
      },
    );
  });

  group('refreshInformation', () {
    blocTest<InformationCubit, InformationState>(
      'updates without emitting InformationLoading',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      seed: () => const InformationLoaded(
        information: [],
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.refreshInformation(),
      expect: () => [
        isA<InformationLoaded>().having(
          (s) => s.information.length,
          'information.length',
          1,
        ),
      ],
    );

    blocTest<InformationCubit, InformationState>(
      'emits InformationLoaded with empty items when cache returns empty on '
      'refresh and does not retain previous information',
      seed: () => const InformationLoaded(
        information: tList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      build: () {
        when(() => mockGetInformationUseCase(any())).thenAnswer(
          (_) async =>
              const Right(InformationResult(items: [], isFromCache: true)),
        );
        return cubit;
      },
      act: (c) => c.refreshInformation(),
      expect: () => [
        isA<InformationLoaded>()
            .having((s) => s.information, 'information', isEmpty)
            .having((s) => s.isFromCache, 'isFromCache', isTrue),
      ],
    );

    blocTest<InformationCubit, InformationState>(
      'retains cachedInformation when refreshInformation fails',
      seed: () => const InformationLoaded(
        information: tList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      build: () {
        when(() => mockGetInformationUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Koneksi terputus')),
        );
        return cubit;
      },
      act: (c) => c.refreshInformation(),
      expect: () => [
        isA<InformationError>()
            .having((e) => e.message, 'message', 'Koneksi terputus')
            .having((e) => e.cachedInformation, 'cachedInformation', tList)
            .having(
              (e) => e.isFromCache,
              'isFromCache is true when cached',
              true,
            ),
      ],
    );

    blocTest<InformationCubit, InformationState>(
      'clears cachedInformation when fetchInformation with new query fails',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      seed: () => const InformationLoaded(
        information: tList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.fetchInformation(search: 'Budi'),
      expect: () => [
        isA<InformationError>()
            .having((e) => e.message, 'message', 'Server Error')
            .having((e) => e.cachedInformation, 'cachedInformation', isEmpty),
      ],
    );
  });

  group('resetFilters', () {
    blocTest<InformationCubit, InformationState>(
      'resets filters and clears search query to null',
      seed: () => const InformationLoaded(
        information: tList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.thisMonth,
        searchQuery: 'laporan',
      ),
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.resetFilters(),
      verify: (_) {
        verify(
          () => mockGetInformationUseCase(
            any(
              that: isA<GetInformationParams>()
                  .having((p) => p.search, 'search', isNull)
                  .having((p) => p.startDate, 'startDate', isNotNull)
                  .having((p) => p.endDate, 'endDate', isNotNull),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as InformationLoaded;
        expect(loaded.searchQuery, isNull);
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
      },
    );

    blocTest<InformationCubit, InformationState>(
      'resetDateFilter clears date filter while preserving search query '
      'and author',
      seed: () => const InformationLoaded(
        information: tList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.thisMonth,
        searchQuery: 'laporan',
        filterAuthorEmail: 'admin@kawalo.id',
      ),
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.resetDateFilter(),
      verify: (_) {
        verify(
          () => mockGetInformationUseCase(
            any(
              that: isA<GetInformationParams>()
                  .having((p) => p.search, 'search', 'laporan')
                  .having((p) => p.createdBy, 'createdBy', 'admin@kawalo.id')
                  .having((p) => p.startDate, 'startDate', isNotNull)
                  .having((p) => p.endDate, 'endDate', isNotNull),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as InformationLoaded;
        expect(loaded.searchQuery, 'laporan');
        expect(loaded.filterAuthorEmail, 'admin@kawalo.id');
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
      },
    );
  });

  group('setFilter', () {
    blocTest<InformationCubit, InformationState>(
      'triggers fetchInformation with new filter period',
      build: () {
        when(
          () => mockGetInformationUseCase(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.setFilter(
        const AppDateFilterResult(period: AppDateFilterPeriod.thisWeek),
      ),
      expect: () => [
        const InformationLoading(),
        isA<InformationLoaded>().having(
          (s) => s.filterPeriod,
          'filterPeriod',
          AppDateFilterPeriod.thisWeek,
        ),
      ],
    );
  });

  group('deleteInformation', () {
    test('removes item from InformationLoaded state on success', () async {
      when(
        () => mockDeleteInformationUseCase(any()),
      ).thenAnswer((_) async => const Right(null));

      cubit.emit(
        const InformationLoaded(information: [tItem], lastSync: '10:00'),
      );

      final result = await cubit.deleteInformation(tItem, session: tSession);

      expect(result.isRight(), isTrue);
      expect(cubit.state, isA<InformationLoaded>());
      final loaded = cubit.state as InformationLoaded;
      expect(loaded.information, isEmpty);
    });

    test('does not mutate InformationLoaded state on failure', () async {
      when(() => mockDeleteInformationUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal menghapus data.')),
      );

      cubit.emit(
        const InformationLoaded(information: [tItem], lastSync: '10:00'),
      );

      final result = await cubit.deleteInformation(tItem, session: tSession);

      expect(result.isLeft(), isTrue);
      final loaded = cubit.state as InformationLoaded;
      expect(loaded.information.length, 1);
    });

    test(
      'deleteMultipleInformation removes selected items on success',
      () async {
        when(() => mockDeleteBatchInformationUseCase(any())).thenAnswer(
          (_) async => const Right(DeleteBatchResult(deletedCount: 1)),
        );

        cubit.emit(
          const InformationLoaded(information: [tItem], lastSync: '10:00'),
        );

        final result = await cubit.deleteMultipleInformation({
          '1',
        }, session: tSession);

        expect(result.isRight(), isTrue);
        expect(cubit.state, isA<InformationLoaded>());
        final loaded = cubit.state as InformationLoaded;
        expect(loaded.information, isEmpty);
      },
    );

    test(
      'deleteMultipleInformation does not mutate state on failure',
      () async {
        when(() => mockDeleteBatchInformationUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal menghapus batch.')),
        );

        cubit.emit(
          const InformationLoaded(information: [tItem], lastSync: '10:00'),
        );

        final result = await cubit.deleteMultipleInformation({
          '1',
        }, session: tSession);

        expect(result.isLeft(), isTrue);
        final loaded = cubit.state as InformationLoaded;
        expect(loaded.information.length, 1);
      },
    );
  });

  group('changeAuthorFilter', () {
    const tItemOther = InformationItemEntity(
      id: '2',
      photos: [],
      title: 'Patroli Regu B',
      userEmail: 'other@kawalo.id',
    );

    test(
      'changes author filter and fetches server-filtered information',
      () async {
        when(() => mockGetInformationUseCase(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.first as GetInformationParams;
          if (params.createdBy == 'satpam@kawalo.id') {
            return const Right(InformationResult(items: [tItem]));
          }
          return const Right(InformationResult(items: [tItem, tItemOther]));
        });

        cubit.emit(
          const InformationLoaded(
            information: [tItem, tItemOther],
            lastSync: '10:00',
          ),
        );

        final initialLoaded = cubit.state as InformationLoaded;
        expect(initialLoaded.displayedInformation.length, 2);

        await cubit.changeAuthorFilter(
          email: 'satpam@kawalo.id',
          name: 'Budi Santoso',
        );

        final mineLoaded = cubit.state as InformationLoaded;
        expect(mineLoaded.filterAuthorEmail, 'satpam@kawalo.id');
        expect(mineLoaded.filterAuthorName, 'Budi Santoso');
        expect(mineLoaded.hasActiveAuthorFilter, isTrue);
        expect(mineLoaded.displayedInformation.length, 1);
        expect(mineLoaded.displayedInformation.first.id, '1');
        verify(
          () => mockGetInformationUseCase(
            any(
              that: isA<GetInformationParams>().having(
                (p) => p.createdBy,
                'createdBy',
                'satpam@kawalo.id',
              ),
            ),
          ),
        ).called(1);

        await cubit.changeAuthorFilter();

        final allLoaded = cubit.state as InformationLoaded;
        expect(allLoaded.filterAuthorEmail, isNull);
        expect(allLoaded.filterAuthorName, isNull);
        expect(allLoaded.hasActiveAuthorFilter, isFalse);
        expect(allLoaded.displayedInformation.length, 2);
        verify(
          () => mockGetInformationUseCase(
            any(
              that: isA<GetInformationParams>().having(
                (p) => p.createdBy,
                'createdBy',
                isNull,
              ),
            ),
          ),
        ).called(1);
      },
    );

    group('loadGroupMembers', () {
      late MockGroupRepository mockGroupRepository;

      setUp(() {
        mockGroupRepository = MockGroupRepository();
      });

      test('returns remote group members when use case succeeds', () async {
        const tMembers = [
          GroupMemberEntity(email: 'author1@kawalo.id', name: 'Author One'),
          GroupMemberEntity(email: 'author2@kawalo.id', name: 'Author Two'),
        ];

        when(
          () => mockGroupRepository.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => const Right(tMembers));

        final cubitWithMembers = InformationCubit(
          getInformationUseCase: mockGetInformationUseCase,
          deleteInformationUseCase: mockDeleteInformationUseCase,
          deleteBatchInformationUseCase: mockDeleteBatchInformationUseCase,
          groupRepository: mockGroupRepository,
        );

        final result = await cubitWithMembers.loadGroupMembers();

        expect(result, const Right<Failure, List<GroupMemberEntity>>(tMembers));
        verify(
          () => mockGroupRepository.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        await cubitWithMembers.close();
      });

      test('returns failure when remote fetch fails', () async {
        const tFailure = ServerFailure('Server Error');
        when(
          () => mockGroupRepository.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        final cubitWithMembers = InformationCubit(
          getInformationUseCase: mockGetInformationUseCase,
          deleteInformationUseCase: mockDeleteInformationUseCase,
          deleteBatchInformationUseCase: mockDeleteBatchInformationUseCase,
          groupRepository: mockGroupRepository,
        );

        final result = await cubitWithMembers.loadGroupMembers();

        expect(result, const Left<Failure, List<GroupMemberEntity>>(tFailure));
        verify(
          () => mockGroupRepository.getMembers(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        await cubitWithMembers.close();
      });

      test('returns failure when groupRepository is null', () async {
        final result = await cubit.loadGroupMembers();

        expect(
          result,
          const Left<Failure, List<GroupMemberEntity>>(
            ServerFailure('Layanan anggota grup tidak tersedia.'),
          ),
        );
      });
    });
  });
}
