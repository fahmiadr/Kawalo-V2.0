import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_toolbar.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';

class MockGuestCubit extends Mock implements GuestCubit {}

class MockGuestFormCubit extends Mock implements GuestFormCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const GuestItemEntity(id: '1'));
  });

  const sampleExitedGuest = GuestFixtures.sampleExitedGuest;
  const sampleWaitingGuest = GuestFixtures.sampleWaitingGuest;

  Widget buildDetailWidget(GuestItemEntity item) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: GuestDetailScreen(item: item),
    );
  }

  group('GuestDetailScreen Widget Tests', () {
    testWidgets(
      'renders exactly 3 cards, meta info, and details for exited guest',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildDetailWidget(sampleExitedGuest));
        await tester.pumpAndSettle();

        // Top Meta: Waktu pembaruan client & Nama Grup
        expect(find.byType(AppHomeAppBar), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data?.startsWith('Diperbarui') ?? false),
          ),
          findsOneWidget,
        );
        expect(find.text(sampleExitedGuest.displayGroupName), findsOneWidget);

        // Card 1: Timeline
        expect(find.text('Masuk'), findsOneWidget);
        expect(find.text(sampleExitedGuest.displayEntryTime), findsOneWidget);
        expect(find.text('Konfirmasi'), findsOneWidget);
        expect(
          find.text(sampleExitedGuest.displayConfirmationTime),
          findsOneWidget,
        );
        expect(find.text('Keluar'), findsOneWidget);
        expect(find.text(sampleExitedGuest.displayExitTime), findsOneWidget);

        // Card 2: Profil & Identitas Tamu
        expect(find.text(sampleExitedGuest.displayName), findsOneWidget);
        expect(
          find.text('No. tamu: ${sampleExitedGuest.displayGuestNumber}'),
          findsOneWidget,
        );
        expect(
          find.text(
            '${sampleExitedGuest.displayIdentityType}: '
            '${sampleExitedGuest.displayIdNumber}',
          ),
          findsOneWidget,
        );
        expect(find.text('Alamat asal'), findsOneWidget);
        expect(find.text(sampleExitedGuest.displayAddress), findsOneWidget);
        expect(find.text('Kode akses QR'), findsOneWidget);
        expect(find.text(sampleExitedGuest.displayQrUid), findsOneWidget);
        expect(find.text('Salin kode'), findsOneWidget);

        // Card 3: Informasi Kunjungan & Penanggung Jawab
        expect(find.text('Detail kunjungan'), findsOneWidget);
        expect(find.text('Tujuan'), findsOneWidget);
        expect(find.text(sampleExitedGuest.displayPurpose), findsOneWidget);
        expect(find.text('Destinasi'), findsOneWidget);
        expect(find.text(sampleExitedGuest.displayDestination), findsOneWidget);

        expect(find.text('Bertemu dengan'), findsOneWidget);
        expect(find.text('Petugas pencatat dan verifikasi'), findsOneWidget);
        expect(find.text('Dicatat oleh'), findsOneWidget);

        // In fixture data, host, recorder, and checkout share the same email
        expect(
          find.text(sampleExitedGuest.displayGuestToUserName),
          findsNWidgets(2),
        );
        expect(
          find.text(sampleExitedGuest.displayGuestToUserEmail),
          findsNWidgets(3),
        );

        // Verify exactly 3 cards use AppCard with elevated variant
        expect(find.byType(AppCard), findsNWidgets(3));
        for (final card in tester.widgetList<AppCard>(find.byType(AppCard))) {
          expect(card.variant, equals(AppCardVariant.elevated));
        }

        // Verify SOS Extended FAB does not exist (removed)
        expect(find.byType(AppExtendedFab), findsNothing);
        expect(find.text('SOS'), findsNothing);
      },
    );

    tearDown(AppSnackbar.hideCurrent);

    testWidgets(
      'tapping Salin kode button copies QR to clipboard and shows snackbar',
      (WidgetTester tester) async {
        final methodCalls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            methodCalls.add(methodCall);
            return null;
          },
        );

        await tester.pumpWidget(buildDetailWidget(sampleExitedGuest));
        await tester.pumpAndSettle();

        final copyButton = find.widgetWithText(AppButton, 'Salin kode');
        expect(copyButton, findsOneWidget);

        await tester.ensureVisible(copyButton);
        await tester.tap(copyButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final copyCall = methodCalls.firstWhere(
          (call) => call.method == 'Clipboard.setData',
        );
        final arguments = copyCall.arguments as Map<dynamic, dynamic>;
        expect(arguments['text'], equals(sampleExitedGuest.displayQrUid));

        expect(
          find.text('Kode akses QR disalin ke papan klip.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders correctly for waiting guest (status Menunggu)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDetailWidget(sampleWaitingGuest));
      await tester.pumpAndSettle();

      expect(find.text(sampleWaitingGuest.displayName), findsOneWidget);
      expect(find.text('-'), findsOneWidget); // exit time is '-'
      expect(find.text('Ahmad Subarjo'), findsOneWidget);
      expect(find.text('ahmad@kawalo.id'), findsOneWidget);
    });

    testWidgets('renders correctly for DetailTamu2 '
        '(pending confirmation & exit with "-")', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildDetailWidget(GuestFixtures.sampleDetailTamu2Guest),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(GuestFixtures.sampleDetailTamu2Guest.displayName),
        findsOneWidget,
      );
      expect(
        find.text(
          'No. tamu: '
          '${GuestFixtures.sampleDetailTamu2Guest.displayGuestNumber}',
        ),
        findsOneWidget,
      );
      expect(find.text('Jemput Mr Sean'), findsOneWidget);
      expect(find.text('Wisnu wijayadi'), findsNWidgets(2));
      expect(find.text('wisnu@veranda.com'), findsNWidgets(2));
    });

    testWidgets('does not render SOS Extended FAB', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDetailWidget(sampleExitedGuest));
      await tester.pumpAndSettle();

      expect(find.byType(AppExtendedFab), findsNothing);
      expect(find.text('SOS'), findsNothing);
    });

    testWidgets('renders safely under 200% dynamic text scaling', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildDetailWidget(sampleExitedGuest));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Detail kunjungan'), findsOneWidget);
      expect(find.text(sampleExitedGuest.displayName), findsOneWidget);
    });

    testWidgets('navigateToGuestDetailScreen pushes standard M3E screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => navigateToGuestDetailScreen(
                  context,
                  item: sampleExitedGuest,
                ),
                child: const Text('Buka Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Detail'));
      await tester.pumpAndSettle();

      // Verify title in top app bar and content
      expect(find.text('Detail tamu'), findsOneWidget);
      expect(find.byType(GuestDetailScreen), findsOneWidget);
      expect(find.text(sampleExitedGuest.displayName), findsOneWidget);

      // Verify back button pops the route
      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();

      expect(find.text('Buka Detail'), findsOneWidget);
      expect(find.byType(GuestDetailScreen), findsNothing);
    });

    testWidgets('pull-to-refresh on GuestDetailScreen triggers refresh and '
        'shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(buildDetailWidget(sampleExitedGuest));
      await tester.pumpAndSettle();

      expect(find.byType(AppHomeAppBar), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Diperbarui') ?? false),
        ),
        findsOneWidget,
      );

      await tester.fling(
        find.text('Log aktivitas'),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Data tamu berhasil diperbarui.'), findsOneWidget);
    });

    testWidgets(
      'renders 3 toolbar buttons with high emphasis on Tambah for ADMIN role',
      (tester) async {
        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(adminSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const GuestDetailScreen(item: sampleExitedGuest),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppToolbar), findsOneWidget);

        final deleteBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is AppIconButton &&
              w.semanticLabel == 'Hapus data tamu Bambang Sudarsono',
        );
        final createBtnFinder = find.byWidgetPredicate(
          (w) => w is AppIconButton && w.semanticLabel == 'Tambah data tamu',
        );
        final editBtnFinder = find.byWidgetPredicate(
          (w) =>
              w is AppIconButton &&
              w.semanticLabel == 'Edit data tamu Bambang Sudarsono',
        );

        expect(deleteBtnFinder, findsOneWidget);
        expect(createBtnFinder, findsOneWidget);
        expect(editBtnFinder, findsOneWidget);

        expect(
          tester.widget<AppIconButton>(deleteBtnFinder).variant,
          AppIconButtonColor.standard,
        );
        expect(
          tester.widget<AppIconButton>(createBtnFinder).variant,
          AppIconButtonColor.filled,
        );
        expect(
          tester.widget<AppIconButton>(editBtnFinder).variant,
          AppIconButtonColor.standard,
        );
      },
    );

    testWidgets(
      'renders all 3 toolbar buttons for GUARD role on own created guest',
      (tester) async {
        const guardOwnSession = AuthSessionEntity(
          userId: '2',
          email: 'wisnu@veranda.com',
          name: 'Wisnu',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(guardOwnSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const GuestDetailScreen(item: sampleExitedGuest),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppToolbar), findsOneWidget);
        expect(
          find.bySemanticsLabel('Hapus data tamu Bambang Sudarsono'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Tambah data tamu'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Edit data tamu Bambang Sudarsono'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows only Tambah button for GUARD role on someone else guest',
      (tester) async {
        const guardOtherSession = AuthSessionEntity(
          userId: '3',
          email: 'other_guard@kawalo.id',
          name: 'Other Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(guardOtherSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const GuestDetailScreen(item: sampleExitedGuest),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppToolbar), findsOneWidget);
        expect(find.bySemanticsLabel('Tambah data tamu'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Hapus data tamu Bambang Sudarsono'),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('Edit data tamu Bambang Sudarsono'),
          findsNothing,
        );
      },
    );

    testWidgets('hides toolbar for non-ADMIN and non-GUARD roles', (
      tester,
    ) async {
      const viewerSession = AuthSessionEntity(
        userId: '4',
        email: 'viewer@kawalo.id',
        name: 'Warga Komplek',
        role: 'VIEWER',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(viewerSession),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const GuestDetailScreen(item: sampleExitedGuest),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppToolbar), findsNothing);
      expect(
        find.bySemanticsLabel('Hapus data tamu Bambang Sudarsono'),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Tambah data tamu'), findsNothing);
      expect(
        find.bySemanticsLabel('Edit data tamu Bambang Sudarsono'),
        findsNothing,
      );
    });

    testWidgets('tapping create button opens GuestFormDialog', (tester) async {
      final mockCubit = MockGuestCubit();
      when(() => mockCubit.state).thenReturn(
        const GuestLoaded(guests: [sampleExitedGuest], lastSync: '10:00'),
      );
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<GuestState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');

      final mockFormCubit = MockGuestFormCubit();
      when(() => mockFormCubit.state).thenReturn(const GuestFormState());
      when(
        () => mockFormCubit.stream,
      ).thenAnswer((_) => const Stream<GuestFormState>.empty());

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(adminSession),
            ),
            BlocProvider<GuestFormCubit>.value(value: mockFormCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: GuestDetailScreen(item: sampleExitedGuest, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final createBtn = find.bySemanticsLabel('Tambah data tamu');
      expect(createBtn, findsOneWidget);

      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);
    });

    testWidgets('tapping edit button opens GuestFormDialog', (tester) async {
      final mockCubit = MockGuestCubit();
      when(() => mockCubit.state).thenReturn(
        const GuestLoaded(guests: [sampleExitedGuest], lastSync: '10:00'),
      );
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<GuestState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');

      final mockFormCubit = MockGuestFormCubit();
      when(() => mockFormCubit.state).thenReturn(
        const GuestFormState(
          mode: GuestFormMode.update,
          name: 'Bambang Sudarsono',
        ),
      );
      when(
        () => mockFormCubit.stream,
      ).thenAnswer((_) => const Stream<GuestFormState>.empty());

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(adminSession),
            ),
            BlocProvider<GuestFormCubit>.value(value: mockFormCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: GuestDetailScreen(item: sampleExitedGuest, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editBtn = find.bySemanticsLabel('Edit data tamu Bambang Sudarsono');
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);
    });

    testWidgets(
      'tapping delete shows confirmation dialog and cancel dismisses',
      (tester) async {
        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'admin@kawalo.id',
          name: 'Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(adminSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const GuestDetailScreen(item: sampleExitedGuest),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final deleteBtn = find.bySemanticsLabel(
          'Hapus data tamu Bambang Sudarsono',
        );
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AppConfirmationDialog), findsOneWidget);
        expect(find.text('Hapus data tamu?'), findsOneWidget);
        expect(
          find.text(
            'Data tamu "Bambang Sudarsono" akan dihapus secara permanen.',
          ),
          findsOneWidget,
        );

        // Tap Batal
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Hapus data tamu?'), findsNothing);
      },
    );

    testWidgets('shows confirmation dialog, displays loading overlay, '
        'and executes delete on confirm', (tester) async {
      final deleteCompleter = Completer<Either<Failure, void>>();
      final mockCubit = MockGuestCubit();

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      when(() => mockCubit.state).thenReturn(
        const GuestLoaded(guests: [sampleExitedGuest], lastSync: '10:00'),
      );
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<GuestState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
      when(
        () => mockCubit.deleteGuest(any(), session: any(named: 'session')),
      ).thenAnswer((_) => deleteCompleter.future);

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(adminSession),
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: GuestDetailScreen(item: sampleExitedGuest, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.bySemanticsLabel(
        'Hapus data tamu Bambang Sudarsono',
      );
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsOneWidget);
      expect(find.text('Hapus data tamu?'), findsOneWidget);

      // Tap Hapus
      await tester.tap(find.text('Hapus'));
      await tester.pump();

      expect(find.byType(AppLoadingOverlay), findsOneWidget);

      deleteCompleter.complete(const Right(null));
      await tester.pumpAndSettle();

      verify(
        () => mockCubit.deleteGuest(sampleExitedGuest, session: adminSession),
      ).called(1);
      expect(find.text('Data tamu berhasil dihapus.'), findsOneWidget);
    });

    testWidgets(
      'GUARD can delete their own guest and passes guardOwnSession to '
      'deleteGuest',
      (tester) async {
        final deleteCompleter = Completer<Either<Failure, void>>();
        final mockCubit = MockGuestCubit();

        const guardOwnSession = AuthSessionEntity(
          userId: '2',
          email: 'wisnu@veranda.com',
          name: 'Guard Wisnu',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );

        const ownGuest = sampleExitedGuest;

        when(
          () => mockCubit.state,
        ).thenReturn(const GuestLoaded(guests: [ownGuest], lastSync: '10:00'));
        when(
          () => mockCubit.stream,
        ).thenAnswer((_) => const Stream<GuestState>.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.deleteGuest(any(), session: any(named: 'session')),
        ).thenAnswer((_) => deleteCompleter.future);

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(guardOwnSession),
            child: M3EMaterialApp(
              data: AppTheme.m3eLight(),
              home: GuestDetailScreen(item: ownGuest, cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final deleteBtn = find.bySemanticsLabel(
          'Hapus data tamu Bambang Sudarsono',
        );
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus'));
        await tester.pump();

        deleteCompleter.complete(const Right(null));
        await tester.pumpAndSettle();

        verify(
          () => mockCubit.deleteGuest(ownGuest, session: guardOwnSession),
        ).called(1);
        expect(find.text('Data tamu berhasil dihapus.'), findsOneWidget);
      },
    );

    testWidgets('shows error snackbar and dismisses loading overlay '
        'when deleteGuest fails', (tester) async {
      final deleteCompleter = Completer<Either<Failure, void>>();
      final mockCubit = MockGuestCubit();

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      when(() => mockCubit.state).thenReturn(
        const GuestLoaded(guests: [sampleExitedGuest], lastSync: '10:00'),
      );
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<GuestState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
      when(
        () => mockCubit.deleteGuest(any(), session: any(named: 'session')),
      ).thenAnswer((_) => deleteCompleter.future);

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(adminSession),
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: GuestDetailScreen(item: sampleExitedGuest, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.bySemanticsLabel(
        'Hapus data tamu Bambang Sudarsono',
      );
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus'));
      await tester.pump();

      expect(find.byType(AppLoadingOverlay), findsOneWidget);

      deleteCompleter.complete(
        const Left(ServerFailure('Gagal menghapus data tamu di server.')),
      );
      await tester.pumpAndSettle();

      verify(
        () => mockCubit.deleteGuest(sampleExitedGuest, session: adminSession),
      ).called(1);

      expect(find.text('Gagal menghapus data tamu di server.'), findsOneWidget);
      expect(find.byType(GuestDetailScreen), findsOneWidget);
    });

    testWidgets('disables delete button when offline', (tester) async {
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      final offlineConnectivityCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(adminSession),
            ),
            BlocProvider<ConnectivityCubit>.value(
              value: offlineConnectivityCubit,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const GuestDetailScreen(item: sampleExitedGuest),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.byWidgetPredicate(
        (w) =>
            w is AppIconButton &&
            w.semanticLabel == 'Hapus data tamu Bambang Sudarsono',
      );
      final createBtnFinder = find.byWidgetPredicate(
        (w) => w is AppIconButton && w.semanticLabel == 'Tambah data tamu',
      );
      final editBtnFinder = find.byWidgetPredicate(
        (w) =>
            w is AppIconButton &&
            w.semanticLabel == 'Edit data tamu Bambang Sudarsono',
      );

      expect(deleteBtnFinder, findsOneWidget);
      expect(createBtnFinder, findsOneWidget);
      expect(editBtnFinder, findsOneWidget);

      expect(tester.widget<AppIconButton>(deleteBtnFinder).onPressed, isNull);
      expect(tester.widget<AppIconButton>(createBtnFinder).onPressed, isNull);
      expect(tester.widget<AppIconButton>(editBtnFinder).onPressed, isNull);

      expect(
        tester.widget<AppIconButton>(deleteBtnFinder).variant,
        AppIconButtonColor.standard,
      );
      expect(
        tester.widget<AppIconButton>(createBtnFinder).variant,
        AppIconButtonColor.filled,
      );
      expect(
        tester.widget<AppIconButton>(editBtnFinder).variant,
        AppIconButtonColor.standard,
      );

      expect(find.byType(AppBottomOfflineBanner), findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsNothing);
    });

    testWidgets('hides AppBottomOfflineBanner when online', (
      WidgetTester tester,
    ) async {
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      final onlineConnectivityCubit = ConnectivityCubit(autoStart: false);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(adminSession),
            ),
            BlocProvider<ConnectivityCubit>.value(
              value: onlineConnectivityCubit,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const GuestDetailScreen(item: sampleExitedGuest),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsNothing,
      );
      expect(find.text('Kembali online'), findsNothing);
      final banner = tester.widget<AppBottomOfflineBanner>(
        find.byType(AppBottomOfflineBanner),
      );
      expect(banner.isOffline, isFalse);
    });

    testWidgets(
      'shows Check-out button in AppBar for active guest and Guard session',
      (tester) async {
        const guardSession = AuthSessionEntity(
          userId: '2',
          email: 'guard@kawalo.id',
          name: 'Guard Duty',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<UserSessionCubit>.value(
                value: UserSessionCubit(guardSession),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const GuestDetailScreen(item: sampleWaitingGuest),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Check-out'), findsOneWidget);
      },
    );

    testWidgets('hides Check-out button for exited guest or Resident session', (
      tester,
    ) async {
      const residentSession = AuthSessionEntity(
        userId: '3',
        email: 'resident@kawalo.id',
        name: 'Resident',
        role: 'RESIDENT',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );

      // Exited guest under Guard session
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(residentSession),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const GuestDetailScreen(item: sampleWaitingGuest),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Check-out'), findsNothing);
    });

    testWidgets(
      'checkout flow executes confirmation and triggers cubit.checkoutGuest',
      (tester) async {
        const guardSession = AuthSessionEntity(
          userId: '2',
          email: 'guard@kawalo.id',
          name: 'Guard Duty',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        final mockCubit = MockGuestCubit();
        const updatedGuest = GuestItemEntity(
          id: '2',
          guestName: 'Reni Marsiti',
          guestOutDt: '2026-11-02T12:00:00.000Z',
        );

        when(() => mockCubit.state).thenReturn(
          const GuestLoaded(guests: [sampleWaitingGuest], lastSync: ''),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('');
        when(
          () => mockCubit.checkoutGuest(
            any(),
            session: any(named: 'session'),
            qrUid: any(named: 'qrUid'),
          ),
        ).thenAnswer((_) async => const Right(updatedGuest));

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<UserSessionCubit>.value(
                value: UserSessionCubit(guardSession),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: GuestDetailScreen(
                item: sampleWaitingGuest,
                cubit: mockCubit,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkoutBtn = find.text('Check-out');
        expect(checkoutBtn, findsOneWidget);

        await tester.tap(checkoutBtn);
        await tester.pumpAndSettle();

        // Confirmation dialog should be visible
        expect(find.byType(AppConfirmationDialog), findsOneWidget);
        expect(find.text('Check-out tamu?'), findsOneWidget);

        // Tap confirm "Check-out" button in dialog
        final confirmBtn = find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Check-out'),
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        verify(
          () => mockCubit.checkoutGuest(
            sampleWaitingGuest,
            session: guardSession,
          ),
        ).called(1);

        expect(
          find.text('Tamu "Reni Marsiti" berhasil check-out.'),
          findsOneWidget,
        );
      },
    );
  });
}
