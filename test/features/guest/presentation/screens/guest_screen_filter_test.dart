import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockDeleteGuestUseCase extends Mock implements DeleteGuestUseCase {}

class MockDeleteBatchGuestUseCase extends Mock
    implements DeleteBatchGuestUseCase {}

class MockGuestCubit extends Mock implements GuestCubit {}

MockGuestCubit createMockGuestCubit({
  List<GuestItemEntity>? guests,
  String greeting = 'Diperbarui Hari ini, 15.20',
}) {
  final mockCubit = MockGuestCubit();
  when(() => mockCubit.state).thenReturn(
    GuestLoaded(
      guests: guests ?? GuestFixtures.defaultGuestEntities,
      lastSync: greeting,
    ),
  );
  when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => mockCubit.currentGreeting).thenReturn(greeting);
  when(
    () => mockCubit.fetchGuests(
      search: any(named: 'search'),
      filterPeriod: any(named: 'filterPeriod'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      creatorEmail: any(named: 'creatorEmail'),
      creatorName: any(named: 'creatorName'),
    ),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    () => mockCubit.refreshGuests(search: any(named: 'search')),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    mockCubit.resetDateFilter,
  ).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.resetFilters).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.loadGroupMembers).thenAnswer((_) async => const Right([]));
  return mockCubit;
}

void main() {
  Widget buildTestWidget({
    List<GuestItemEntity>? initialGuests,
    GuestCubit? cubit,
  }) {
    final effectiveCubit = cubit ?? createMockGuestCubit(guests: initialGuests);
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: GuestScreen(cubit: effectiveCubit),
    );
  }

  group('GuestScreen Filter & Empty State Tests', () {
    testWidgets('renders "Belum ada data tamu" empty state when active group '
        'has no data', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialGuests: const []));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data tamu'), findsOneWidget);
      expect(
        find.text('Belum ada kunjungan tamu pada hari ini.'),
        findsOneWidget,
      );
      expect(find.text('Atur Ulang Filter'), findsNothing);
    });

    testWidgets('renders "Data tamu tidak ditemukan" and resets via button '
        'when no match', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      registerFallbackValue(const GetGuestsParams());
      final mockGuestRepository = MockGuestRepository();
      when(() => mockGuestRepository.getGuests(any())).thenAnswer((
        invocation,
      ) async {
        final params = invocation.positionalArguments.first as GetGuestsParams;
        if (params.search?.toLowerCase() == 'tidakadanamaini') {
          return const Right(GuestResult(items: []));
        }
        return const Right(
          GuestResult(items: GuestFixtures.defaultGuestEntities),
        );
      });

      final cubit = GuestCubit(
        guestRepository: mockGuestRepository,
        deleteGuestUseCase: MockDeleteGuestUseCase(),
        deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(GuestCard), findsNWidgets(5));

      // Buka search bar via toggle button
      await tester.tap(find.bySemanticsLabel('Cari data tamu'));
      await tester.pumpAndSettle();

      // Masukkan pencarian yang tidak menghasilkan kecocokan
      await tester.enterText(find.byType(AppSearchBar), 'TidakAdaNamaIni');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(GuestCard), findsNothing);
      expect(find.text('Data tamu tidak ditemukan'), findsOneWidget);
      expect(find.text('Reset filter & pencarian'), findsOneWidget);

      // Tekan tombol Reset Filter & Pencarian
      await tester.tap(find.text('Reset filter & pencarian'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Daftar tamu pulih
      expect(find.byType(GuestCard), findsNWidgets(5));
      expect(find.text('Data tamu tidak ditemukan'), findsNothing);

      await cubit.close();
    });

    testWidgets('tapping Tanggal filter chip opens bottom sheet and updates '
        'filter chip label when active', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      registerFallbackValue(const GetGuestsParams());
      final mockGuestRepository = MockGuestRepository();
      when(() => mockGuestRepository.getGuests(any())).thenAnswer(
        (_) async =>
            const Right(GuestResult(items: GuestFixtures.defaultGuestEntities)),
      );

      final cubit = GuestCubit(
        guestRepository: mockGuestRepository,
        deleteGuestUseCase: MockDeleteGuestUseCase(),
        deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Buka filter bottom sheet melalui filter chip Tanggal
      final filterChip = find.text('Tanggal');
      expect(filterChip, findsOneWidget);
      await tester.tap(filterChip);
      await tester.pumpAndSettle();

      // Bottom sheet muncul
      expect(
        find.descendant(
          of: find.byType(AppDateFilterBottomSheet),
          matching: find.text('Tanggal'),
        ),
        findsOneWidget,
      );
      expect(find.text('Rentang waktu'), findsOneWidget);

      // Pilih filter Bulan ini lalu terapkan
      await tester.tap(find.text('Bulan ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      // Chip tanggal sekarang aktif dan menampilkan "Bulan ini"
      expect(find.text('Bulan ini'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      'filter "Hari ini" applies correctly and filters out past guests',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.first as GetGuestsParams;
          if (params.startDate != null) {
            return const Right(
              GuestResult(items: [GuestFixtures.sampleExitedGuest]),
            );
          }
          return const Right(
            GuestResult(
              items: [
                GuestFixtures.sampleExitedGuest,
                GuestFixtures.samplePastGuest,
              ],
            ),
          );
        });

        final cubit = GuestCubit(
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        await cubit.fetchGuests(filterPeriod: AppDateFilterPeriod.today);

        await tester.pumpWidget(buildTestWidget(cubit: cubit));
        await tester.pumpAndSettle();

        // Tamu hari ini ditampilkan
        expect(find.text('Bambang Sudarsono'), findsOneWidget);
        // Tamu masa lalu (2020) terfilter keluar oleh filter Hari ini
        expect(find.text('Tamu Masa Lalu'), findsNothing);
        expect(find.byType(GuestCard), findsOneWidget);

        await cubit.close();
      },
    );
  });
}
