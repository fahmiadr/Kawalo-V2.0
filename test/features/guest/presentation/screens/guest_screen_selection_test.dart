import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_guests/get_guests_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGuestsUseCase extends Mock implements GetGuestsUseCase {}

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
      guests: guests ?? const [],
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
    () => mockCubit.refreshGuests(
      search: any(named: 'search'),
    ),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.resetDateFilter)
      .thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.resetFilters)
      .thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.loadGroupMembers)
      .thenAnswer((_) async => const Right([]));
  return mockCubit;
}

void main() {
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
    const dummyGuest = GuestItemEntity(id: '1');
    registerFallbackValue(const GetGuestsParams());
    registerFallbackValue(
      const DeleteBatchGuestParams(
        ids: ['1'],
        session: dummySession,
        items: [dummyGuest],
      ),
    );
  });

  tearDown(AppSnackbar.hideCurrent);

  const guardSession = AuthSessionEntity(
    userId: 'guard-1',
    email: 'satpam.budi@kawalo.id',
    name: 'Budi Santoso',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const adminSession = AuthSessionEntity(
    userId: 'admin-1',
    email: 'admin@kawalo.id',
    name: 'Admin Kawalo',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const guest1 = GuestItemEntity(
    id: '1',
    guestName: 'Bambang Sudarsono',
    guestNumber: 'B 1234 CD',
    guestCreatorEmail: 'satpam.budi@kawalo.id',
    guestCreatorName: 'Budi Santoso',
    guestDt: '09 Sep 2026 14:00',
  );

  const guest2 = GuestItemEntity(
    id: '2',
    guestName: 'Reni Marsiti',
    guestNumber: 'B 5678 EF',
    guestCreatorEmail: 'satpam.dani@kawalo.id',
    guestCreatorName: 'Dani Pratama',
    guestDt: '09 Sep 2026 14:30',
  );

  const guest3 = GuestItemEntity(
    id: '3',
    guestName: 'Agus Setiawan',
    guestNumber: 'B 9999 GH',
    guestCreatorEmail: 'satpam.budi@kawalo.id',
    guestCreatorName: 'Budi Santoso',
    guestDt: '09 Sep 2026 15:00',
  );

  Widget buildTestWidget({
    required AuthSessionEntity session,
    List<GuestItemEntity>? initialGuests,
    GuestCubit? cubit,
    ConnectivityCubit? connectivityCubit,
  }) {
    final effectiveCubit = cubit ??
        createMockGuestCubit(
          guests: initialGuests ?? const [guest1, guest2, guest3],
        );
    Widget app = M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: GuestScreen(
        cubit: effectiveCubit,
      ),
    );

    if (connectivityCubit != null) {
      app = BlocProvider<ConnectivityCubit>.value(
        value: connectivityCubit,
        child: app,
      );
    }

    return BlocProvider<UserSessionCubit>.value(
      value: UserSessionCubit(session),
      child: app,
    );
  }

  group('GuestScreen Selection & Batch Delete Tests', () {
    testWidgets(
      'renders AppSelectionAppBar and hides create FAB on long press',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: guardSession),
        );
        await tester.pumpAndSettle();

        expect(find.text('Data tamu'), findsOneWidget);
        expect(find.byType(AppExtendedFab), findsOneWidget);

        // Long press owned card (Bambang)
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();

        // Selection app bar is active with count '1'
        expect(find.byType(AppSelectionAppBar), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Hapus data tamu terpilih'),
          findsOneWidget,
        );

        // Create FAB is hidden in selection mode
        expect(find.byType(AppExtendedFab), findsNothing);
      },
    );

    testWidgets(
      'GUARD cannot select guest card authored by another user on long-press',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: guardSession),
        );
        await tester.pumpAndSettle();

        // Long press non-owned card (Reni - created by Dani)
        await tester.longPress(find.text('Reni Marsiti'));
        await tester.pumpAndSettle();

        // Selection mode should NOT activate
        expect(find.text('Data tamu'), findsOneWidget);
        expect(find.text('1'), findsNothing);
        expect(
          find.text('Anda hanya dapat memilih data tamu yang Anda catat.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GUARD cannot select non-owned guest card on tap when selection '
      'is active',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: guardSession),
        );
        await tester.pumpAndSettle();

        // Enter selection mode on owned card
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);

        // Tap non-owned card (Reni)
        await tester.tap(find.text('Reni Marsiti'));
        await tester.pumpAndSettle();

        // Count remains 1 and snackbar informs user
        expect(find.text('1'), findsOneWidget);
        expect(
          find.text('Anda hanya dapat memilih data tamu yang Anda catat.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ADMIN can select any guest regardless of author',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: adminSession),
        );
        await tester.pumpAndSettle();

        // Admin long-presses non-owned card (Reni)
        await tester.longPress(find.text('Reni Marsiti'));
        await tester.pumpAndSettle();

        // Selection mode activates
        expect(find.text('1'), findsOneWidget);

        // Admin taps Bambang
        await tester.tap(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();

        // Both selected
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'Smart "Pilih semua" selects only owned guests for GUARD',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: guardSession),
        );
        await tester.pumpAndSettle();

        // Long press Bambang to enter selection
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);

        // Tap "Pilih semua"
        await tester.tap(find.text('Pilih semua'));
        await tester.pumpAndSettle();

        // Only guest1 and guest3 (created by satpam.budi) are selected: 2 items
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsNothing);
      },
    );

    testWidgets(
      'Smart "Pilih semua" selects all guests for ADMIN',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: adminSession),
        );
        await tester.pumpAndSettle();

        // Long press Bambang
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);

        // Tap "Pilih semua"
        await tester.tap(find.text('Pilih semua'));
        await tester.pumpAndSettle();

        // All 3 items are selected for ADMIN
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets(
      'Batch deletion flow: confirmation dialog -> confirm -> invokes cubit',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockGetGuestsUseCase = MockGetGuestsUseCase();
        final mockDeleteGuestUseCase = MockDeleteGuestUseCase();
        final mockDeleteBatchUseCase = MockDeleteBatchGuestUseCase();

        when(() => mockGetGuestsUseCase(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: [guest1, guest2, guest3]),
          ),
        );
        when(() => mockDeleteBatchUseCase(any())).thenAnswer(
          (_) async => const Right(
            DeleteBatchResult(deletedCount: 2),
          ),
        );

        final cubit = GuestCubit(
          getGuestsUseCase: mockGetGuestsUseCase,
          deleteGuestUseCase: mockDeleteGuestUseCase,
          deleteBatchGuestUseCase: mockDeleteBatchUseCase,
        );

        await tester.pumpWidget(
          buildTestWidget(
            session: guardSession,
            cubit: cubit,
          ),
        );
        await tester.pumpAndSettle();

        // Select guest1 and guest3
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agus Setiawan'));
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);

        // Tap delete icon
        await tester.tap(find.bySemanticsLabel('Hapus data tamu terpilih'));
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Hapus 2 data tamu?'), findsOneWidget);
        expect(
          find.text('2 data tamu terpilih akan dihapus secara permanen.'),
          findsOneWidget,
        );

        // Tap 'Batal' first to verify dismissal
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        verifyZeroInteractions(mockDeleteBatchUseCase);
        expect(find.text('2'), findsOneWidget);

        // Tap delete icon again and confirm
        await tester.tap(find.bySemanticsLabel('Hapus data tamu terpilih'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        // Verify deleteMultipleGuests called with ids
        verify(
          () => mockDeleteBatchUseCase(
            any(
              that: isA<DeleteBatchGuestParams>().having(
                (p) => p.ids.toSet(),
                'ids',
                {'1', '3'},
              ),
            ),
          ),
        ).called(1);

        // Selection cleared and success message shown
        expect(find.text('2 data tamu berhasil dihapus.'), findsOneWidget);
        expect(find.text('Data tamu'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      'PopScope dismisses selection mode when back navigation is triggered',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(session: guardSession),
        );
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);

        // Verify PopScope traps back navigation when in selection mode
        final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
        expect(popScopeFinder, findsOneWidget);
        final popScope = tester.widget<PopScope<Object?>>(popScopeFinder);
        expect(popScope.canPop, isFalse);

        // Simulate back invocation on PopScope
        popScope.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        // Selection dismissed, default header restored
        expect(find.text('Data tamu'), findsOneWidget);
        expect(find.text('1'), findsNothing);
      },
    );

    testWidgets(
      'pull-to-refresh is disabled when in selection mode',
      (tester) async {
        final mockCubit = createMockGuestCubit(
          guests: const [guest1, guest2, guest3],
        );

        await tester.pumpWidget(
          buildTestWidget(
            session: guardSession,
            cubit: mockCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);

        // Attempt fling to trigger refresh
        await tester.fling(
          find.byType(ListView),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // refreshGuests should NOT be called
        verifyNever(
          () => mockCubit.refreshGuests(search: any(named: 'search')),
        );
      },
    );

    testWidgets(
      'delete button is disabled when offline in selection mode',
      (tester) async {
        final offlineCubit = ConnectivityCubit(
          initialState: ConnectivityStatus.offline,
          autoStart: false,
        );

        await tester.pumpWidget(
          buildTestWidget(
            session: guardSession,
            connectivityCubit: offlineCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.longPress(find.text('Bambang Sudarsono'));
        await tester.pumpAndSettle();

        final deleteBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is AppIconButton &&
              w.semanticLabel == 'Hapus data tamu terpilih',
        );
        expect(deleteBtnFinder, findsOneWidget);

        final iconButton = tester.widget<AppIconButton>(deleteBtnFinder);
        expect(iconButton.onPressed, isNull);
      },
    );
  });
}
