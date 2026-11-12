import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_destructive_button.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_detail_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_file_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_location_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_post_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationCubit extends Mock implements InformationCubit {}

class MockInformationFormCubit extends Mock implements InformationFormCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const InformationItemEntity(id: '1', photos: []));
  });

  group('InformationDetailScreen Widget Tests', () {
    late UserSessionCubit userSessionCubit;

    setUp(() {
      userSessionCubit = UserSessionCubit();
    });

    tearDown(() {
      userSessionCubit.close();
    });

    const dummyFeed = InformationItemEntity(
      id: '101',
      photos: [],
      title: 'Pelatihan Tanggap Darurat',
      text: 'Simulasi latihan kebakaran bersama damkar.',
      userEmail: 'satpam@kawalo.id',
      userName: 'Budi Santoso',
      feedDt: '09 Sep 2026 14:20',
      feedType: 'EVENT',
      groupName: 'JKN Veranda',
      eventLocation: 'Lapangan Timur',
      eventStartDt: '2026-09-12 08:00',
      eventEndDt: '2026-09-12 11:30',
      eventDuration: 3,
      glat: -6.2,
      glong: 106.816666,
    );

    const dummyFeedWithFile = InformationItemEntity(
      id: '102',
      photos: ['https://example.com/photo1.jpg'],
      title: 'Laporan Kerusakan Lampu Jalan',
      text: 'Lampu penerangan jalan padam di area gerbang utara.',
      userEmail: 'patroli@kawalo.id',
      userName: 'Agus Wijaya',
      feedDt: '10 Sep 2026 10:00',
      feedType: 'INCIDENT',
      feedFile: 'laporan_insiden.pdf',
      groupName: 'JKN Veranda',
      eventLocation: 'Gerbang Utara',
      glat: -6.2,
      glong: 106.816666,
    );

    testWidgets('renders Card 1 and Card 2 when no attachment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const InformationDetailScreen(item: dummyFeed),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JKN Veranda'), findsOneWidget);
      expect(find.byType(InformationDetailPostCard), findsOneWidget);
      expect(find.byType(InformationDetailLocationCard), findsOneWidget);
      expect(find.byType(InformationDetailFileSection), findsNothing);
    });

    testWidgets('renders AppHomeAppBar with back button and pops on press', (
      tester,
    ) async {
      var didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Navigator(
            onDidRemovePage: (page) {
              didPop = true;
            },
            pages: const [
              MaterialPage(child: Scaffold(body: Text('Root'))),
              MaterialPage(child: InformationDetailScreen(item: dummyFeed)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.bySemanticsLabel('Kembali');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });

    testWidgets('renders Card 3 when file attachment exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const InformationDetailScreen(item: dummyFeedWithFile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InformationDetailFileSection), findsOneWidget);
    });

    testWidgets('populates fields correctly from dummy data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const InformationDetailScreen(item: dummyFeed),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pelatihan Tanggap Darurat'), findsOneWidget);
      expect(
        find.text('Simulasi latihan kebakaran bersama damkar.'),
        findsOneWidget,
      );
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('satpam@kawalo.id'), findsOneWidget);
      expect(find.text('JKN Veranda'), findsOneWidget);
      expect(find.text('Lapangan Timur'), findsOneWidget);
    });

    testWidgets('renders posting, edit, and delete buttons for ADMIN role', (
      tester,
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
      userSessionCubit.updateSession(adminSession);

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: userSessionCubit,
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const InformationDetailScreen(item: dummyFeed),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppPageActions), findsOneWidget);
      expect(find.bySemanticsLabel('Tambah informasi'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ubah informasi Pelatihan Tanggap Darurat'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Hapus informasi Pelatihan Tanggap Darurat'),
        findsOneWidget,
      );
    });

    testWidgets('renders posting, edit, and delete for GUARD on own post', (
      tester,
    ) async {
      const guardOwnSession = AuthSessionEntity(
        userId: '2',
        email: 'satpam@kawalo.id',
        name: 'Budi Santoso',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      userSessionCubit.updateSession(guardOwnSession);

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: userSessionCubit,
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const InformationDetailScreen(item: dummyFeed),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppPageActions), findsOneWidget);
      expect(find.bySemanticsLabel('Tambah informasi'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ubah informasi Pelatihan Tanggap Darurat'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Hapus informasi Pelatihan Tanggap Darurat'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders posting button but hides edit/delete for GUARD on other post',
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
        userSessionCubit.updateSession(guardOtherSession);

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: userSessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const InformationDetailScreen(item: dummyFeed),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppPageActions), findsOneWidget);
        expect(find.bySemanticsLabel('Tambah informasi'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Ubah informasi Pelatihan Tanggap Darurat'),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('Hapus informasi Pelatihan Tanggap Darurat'),
          findsNothing,
        );
      },
    );

    testWidgets('hides action bar for non-ADMIN and non-GUARD roles', (
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
      userSessionCubit.updateSession(viewerSession);

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: userSessionCubit,
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const InformationDetailScreen(item: dummyFeed),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppPageActions), findsNothing);
      expect(find.text('Ubah'), findsNothing);
      expect(find.text('Tambah Informasi'), findsNothing);
      expect(find.text('Hapus Informasi'), findsNothing);
      expect(find.bySemanticsLabel('Tambah informasi'), findsNothing);
      expect(
        find.bySemanticsLabel('Ubah informasi Pelatihan Tanggap Darurat'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Hapus informasi Pelatihan Tanggap Darurat'),
        findsNothing,
      );
    });

    testWidgets('tapping posting button opens InformationFormDialog', (
      tester,
    ) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(const InformationInitial());
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<InformationState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('10:00');

      final mockFormCubit = MockInformationFormCubit();
      when(() => mockFormCubit.state).thenReturn(const InformationFormState());
      when(
        () => mockFormCubit.stream,
      ).thenAnswer((_) => const Stream<InformationFormState>.empty());

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      userSessionCubit.updateSession(adminSession);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(value: userSessionCubit),
            BlocProvider<InformationFormCubit>.value(value: mockFormCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationDetailScreen(item: dummyFeed, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final postBtn = find.widgetWithText(AppButton, 'Tambah Informasi');
      expect(postBtn, findsOneWidget);

      await tester.tap(postBtn);
      await tester.pumpAndSettle();

      expect(find.byType(InformationFormDialog), findsOneWidget);
    });

    testWidgets('tapping edit button opens InformationFormDialog', (
      tester,
    ) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(const InformationInitial());
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<InformationState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('10:00');

      final mockFormCubit = MockInformationFormCubit();
      when(() => mockFormCubit.state).thenReturn(
        const InformationFormState(
          mode: InformationFormMode.update,
          title: 'Pelatihan Tanggap Darurat',
        ),
      );
      when(
        () => mockFormCubit.stream,
      ).thenAnswer((_) => const Stream<InformationFormState>.empty());

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      userSessionCubit.updateSession(adminSession);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(value: userSessionCubit),
            BlocProvider<InformationFormCubit>.value(value: mockFormCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationDetailScreen(item: dummyFeed, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editBtn = find.bySemanticsLabel(
        'Ubah informasi Pelatihan Tanggap Darurat',
      );
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(InformationFormDialog), findsOneWidget);
    });

    testWidgets('delete flow confirms dialog and triggers cubit', (
      tester,
    ) async {
      final mockCubit = MockInformationCubit();
      final deleteCompleter = Completer<Either<Failure, void>>();

      when(() => mockCubit.state).thenReturn(const InformationInitial());
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<InformationState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('10:00');
      when(
        () =>
            mockCubit.deleteInformation(any(), session: any(named: 'session')),
      ).thenAnswer((_) => deleteCompleter.future);

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      userSessionCubit.updateSession(adminSession);

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: userSessionCubit,
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: InformationDetailScreen(item: dummyFeed, cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.bySemanticsLabel(
        'Hapus informasi Pelatihan Tanggap Darurat',
      );
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsOneWidget);
      expect(find.text('Hapus informasi?'), findsOneWidget);
      expect(
        find.text(
          'Informasi "Pelatihan Tanggap Darurat" akan dihapus secara permanen.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Hapus'));
      await tester.pump();

      expect(find.byType(AppLoadingOverlay), findsOneWidget);

      deleteCompleter.complete(const Right(null));
      await tester.pumpAndSettle();

      verify(
        () => mockCubit.deleteInformation(dummyFeed, session: adminSession),
      ).called(1);
    });

    testWidgets(
      'GUARD can delete their own information and passes guardOwnSession',
      (tester) async {
        final mockCubit = MockInformationCubit();
        final deleteCompleter = Completer<Either<Failure, void>>();

        when(() => mockCubit.state).thenReturn(const InformationInitial());
        when(
          () => mockCubit.stream,
        ).thenAnswer((_) => const Stream<InformationState>.empty());
        when(() => mockCubit.currentGreeting).thenReturn('10:00');
        when(
          () => mockCubit.deleteInformation(
            any(),
            session: any(named: 'session'),
          ),
        ).thenAnswer((_) => deleteCompleter.future);

        const guardOwnSession = AuthSessionEntity(
          userId: '2',
          email: 'satpam@kawalo.id',
          name: 'Budi Satpam',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        userSessionCubit.updateSession(guardOwnSession);

        const ownFeed = dummyFeed;

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: userSessionCubit,
            child: M3EMaterialApp(
              data: AppTheme.m3eLight(),
              home: InformationDetailScreen(item: ownFeed, cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final deleteBtn = find.bySemanticsLabel(
          'Hapus informasi Pelatihan Tanggap Darurat',
        );
        expect(deleteBtn, findsOneWidget);

        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus'));
        await tester.pump();

        deleteCompleter.complete(const Right(null));
        await tester.pumpAndSettle();

        verify(
          () => mockCubit.deleteInformation(ownFeed, session: guardOwnSession),
        ).called(1);
      },
    );

    testWidgets('disables all action buttons when offline', (tester) async {
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      userSessionCubit.updateSession(adminSession);

      final offlineConnectivityCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(value: userSessionCubit),
            BlocProvider<ConnectivityCubit>.value(
              value: offlineConnectivityCubit,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const InformationDetailScreen(item: dummyFeed),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final postBtnFinder = find.widgetWithText(AppButton, 'Tambah Informasi');
      final editBtnFinder = find.widgetWithText(AppButton, 'Ubah');
      final deleteBtnFinder = find.widgetWithText(AppButton, 'Hapus Informasi');

      expect(postBtnFinder, findsOneWidget);
      expect(editBtnFinder, findsOneWidget);
      expect(deleteBtnFinder, findsOneWidget);

      expect(tester.widget<AppButton>(postBtnFinder).enabled, isFalse);
      expect(tester.widget<AppButton>(editBtnFinder).enabled, isFalse);
      expect(tester.widget<AppButton>(deleteBtnFinder).enabled, isFalse);

      expect(find.byType(AppBottomOfflineBanner), findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsNothing);
    });

    testWidgets(
      'stacks Ubah above Tambah Informasi above Hapus Informasi in the '
      'bottom bar, not in the app bar',
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
        userSessionCubit.updateSession(adminSession);

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: userSessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: const InformationDetailScreen(item: dummyFeedWithFile),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final editBtn = find.widgetWithText(AppButton, 'Ubah');
        final createBtn = find.widgetWithText(AppButton, 'Tambah Informasi');
        final deleteBtn = find.widgetWithText(AppButton, 'Hapus Informasi');

        expect(find.byType(AppPageActions), findsOneWidget);
        expect(find.byType(AppDestructiveButton), findsOneWidget);
        expect(tester.widget<AppButton>(editBtn).style, AppButtonColor.filled);
        expect(tester.widget<AppButton>(createBtn).style, AppButtonColor.tonal);

        final editY = tester.getTopLeft(editBtn).dy;
        final createY = tester.getTopLeft(createBtn).dy;
        final deleteY = tester.getTopLeft(deleteBtn).dy;
        expect(editY, lessThan(createY));
        expect(createY, lessThan(deleteY));
        expect(deleteY, greaterThan(500));

        final screenWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        expect(
          tester.getSize(deleteBtn).width,
          closeTo(screenWidth - 2 * 16, 1),
        );
        expect(
          find.descendant(
            of: find.byType(AppHomeAppBar),
            matching: find.textContaining('Hapus'),
          ),
          findsNothing,
        );

        // The bar is fixed: scrolling the content must not move it.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(deleteBtn).dy, deleteY);
      },
    );

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
      userSessionCubit.updateSession(adminSession);

      final onlineConnectivityCubit = ConnectivityCubit(autoStart: false);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(value: userSessionCubit),
            BlocProvider<ConnectivityCubit>.value(
              value: onlineConnectivityCubit,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const InformationDetailScreen(item: dummyFeed),
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
  });
}
