import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/kawalo_logo.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/home/presentation/utils/home_greeting_helper.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/app_navigation_bar.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityStatus>
    implements ConnectivityCubit {}

class MockInformationCubit extends MockCubit<InformationState>
    implements InformationCubit {}

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  const testUser = UserEntity(
    id: 'usr_1',
    email: 'admin@kawalo.co.id',
    name: 'AHMAD ZAKI FAUZAN',
    groups: [],
    activeGroup: UserGroupEntity(
      groupUid: 'grp_1',
      category: 'admin',
      allowAdmin: true,
      allowPatrol: false,
      allowMonPatrol: false,
      features: [],
    ),
  );

  Widget buildTestWidget({
    int initialIndex = 0,
    UserEntity? user = testUser,
    ConnectivityCubit? connectivityCubit,
    List<BlocProvider<dynamic>> extraProviders = const [],
  }) {
    final mockLogin = MockLoginUseCase();
    final mockAuthRepository = MockAuthRepository();
    final mockLogout = MockLogoutUseCase();

    when(
      mockAuthRepository.getCurrentUser,
    ).thenAnswer((_) async => Right(user));
    when(
      mockAuthRepository.getActiveSession,
    ).thenAnswer((_) async => const Right(null));

    final mockInformationCubit = MockInformationCubit();
    when(() => mockInformationCubit.state).thenReturn(
      const InformationLoaded(information: [], lastSync: 'Baru saja'),
    );
    when(
      mockInformationCubit.fetchInformation,
    ).thenAnswer((_) async => AppFetchResult.success);

    Widget child = MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            loginUseCase: mockLogin,
            authRepository: mockAuthRepository,
            logoutUseCase: mockLogout,
          )..add(const AuthCheckRequested()),
        ),
        BlocProvider<InformationCubit>.value(value: mockInformationCubit),
        ...extraProviders,
      ],
      child: MainNavigationScreen(initialIndex: initialIndex),
    );

    if (connectivityCubit != null) {
      child = BlocProvider<ConnectivityCubit>.value(
        value: connectivityCubit,
        child: child,
      );
    }

    return MaterialApp(theme: AppTheme.lightThemeData(), home: child);
  }

  group('MainNavigationScreen Tests', () {
    testWidgets('renders custom AppHomeAppBar on home destination', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final expectedGreeting = HomeGreetingHelper.formatGreeting(
        name: testUser.name,
        role: testUser.activeGroup?.category,
      );

      expect(find.byType(AppHomeAppBar), findsOneWidget);
      expect(find.text(expectedGreeting), findsOneWidget);
      expect(find.byType(KawaloLogoText), findsOneWidget);
    });

    testWidgets(
      'pull-to-refresh on dashboard content area triggers refresh indicator',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppHomeAppBar), findsOneWidget);

        // Fling down pada area konten dashboard
        await tester.fling(
          find.text('Tamu Terakhir'),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Memastikan AppRefreshIndicator terpasang
        expect(find.byType(AppRefreshIndicator), findsWidgets);
      },
    );

    testWidgets('renders all 4 navigation destinations correctly', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Memastikan AppNavigationBar (M3ENavigationBar) terpasang
      expect(find.byType(AppNavigationBar), findsOneWidget);

      // Memastikan 4 label destinasi ada
      expect(find.text('Beranda'), findsAtLeastNWidgets(1));
      expect(find.text('Informasi'), findsAtLeastNWidgets(1));
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);

      // Memastikan konten awal default adalah Beranda (HomeDashboardView)
      expect(find.text('Tamu Terakhir'), findsOneWidget);
      expect(find.text('Absensi'), findsOneWidget);
      expect(find.text('Post to Post Checkpoint'), findsOneWidget);
      expect(find.text('Pintasan'), findsOneWidget);
    });

    testWidgets('switches content when tapping different navigation items', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap tab "Informasi"
      await tester.tap(find.text('Informasi').last);
      await tester.pumpAndSettle();

      expect(find.text('Pusat informasi'), findsOneWidget);
      expect(find.bySemanticsLabel('Cari informasi'), findsOneWidget);
      expect(find.text('Belum ada informasi'), findsOneWidget);

      // Tap tab "Laporan"
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Daftar laporan dan validasi akan ditampilkan di sini.'),
        findsOneWidget,
      );

      // Tap tab "Lainnya"
      await tester.tap(find.text('Lainnya'));
      await tester.pumpAndSettle();

      expect(find.text('AHMAD ZAKI FAUZAN'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Tap kembali ke tab "Beranda"
      await tester.tap(find.text('Beranda').last);
      await tester.pumpAndSettle();

      expect(find.text('Tamu Terakhir'), findsOneWidget);
      expect(find.text('Pintasan'), findsOneWidget);
    });

    testWidgets('supports initialIndex parameter', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 2));
      await tester.pumpAndSettle();

      // Index 2 harusnya Laporan
      expect(
        find.text('Daftar laporan dan validasi akan ditampilkan di sini.'),
        findsOneWidget,
      );
    });

    testWidgets('contains designated Kawalo vectors for all destinations', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verifikasi AppSvgIcon dengan path vektor Kawalo
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppSvgIcon &&
              widget.assetPath == KawaloVectors.home01Filled,
        ),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppSvgIcon && widget.assetPath == KawaloVectors.kanban,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppSvgIcon &&
              widget.assetPath == KawaloVectors.documentValidation,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppSvgIcon &&
              widget.assetPath == KawaloVectors.moreHorizontalCircle01,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not render Extended FAB SOS', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SOS'), findsNothing);
    });

    testWidgets(
      'renders AppBottomOfflineBanner below AppNavigationBar when offline',
      (tester) async {
        final mockConnectivity = MockConnectivityCubit();
        when(
          () => mockConnectivity.state,
        ).thenReturn(ConnectivityStatus.offline);

        await tester.pumpWidget(
          buildTestWidget(connectivityCubit: mockConnectivity),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
        expect(find.byType(AppNavigationBar), findsOneWidget);
        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsOneWidget,
        );
      },
    );

    testWidgets('asks PttCubit to join the active group when opened', (
      tester,
    ) async {
      final pttCubit = MockPttCubit();
      when(() => pttCubit.state).thenReturn(const PttInitial());
      when(() => pttCubit.joinForGroup(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          extraProviders: [
            BlocProvider<PttCubit>.value(value: pttCubit),
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(
                const AuthSessionEntity(
                  userId: 'usr_1',
                  email: 'admin@kawalo.co.id',
                  name: 'Admin',
                  allowAdmin: true,
                  allowPatrol: false,
                  allowMonPatrol: false,
                  groupUid: 'grp_1',
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The auth listener triggers it too; the real cubit dedupes by state.
      verify(
        () => pttCubit.joinForGroup('grp_1'),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
      'notification bell has no fake badge and says it is unavailable',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<AppHomeAppBar>(find.byType(AppHomeAppBar))
              .unreadNotificationsCount,
          0,
        );

        await tester.tap(find.bySemanticsLabel('Notifikasi'));
        await tester.pump();

        expect(find.text('Notifikasi belum tersedia.'), findsOneWidget);
        expect(find.textContaining('belum dibaca'), findsNothing);
        await tester.pumpAndSettle(const Duration(seconds: 6));
      },
    );

    testWidgets('placeholder tabs have no fake pull-to-refresh', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 2));
      await tester.pumpAndSettle();

      // Beranda is offstage; the visible placeholder has no refresh indicator.
      expect(find.byType(AppRefreshIndicator), findsNothing);
      await tester.fling(
        find.text('Daftar laporan dan validasi akan ditampilkan di sini.'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.textContaining('berhasil diperbarui'), findsNothing);
    });

    testWidgets('rejoins PTT with the new group after switch-group', (
      tester,
    ) async {
      final pttCubit = MockPttCubit();
      when(() => pttCubit.state).thenReturn(const PttInitial());
      when(() => pttCubit.joinForGroup(any())).thenAnswer((_) async {});
      final session = UserSessionCubit(
        const AuthSessionEntity(
          userId: 'usr_1',
          email: 'admin@kawalo.co.id',
          name: 'Admin',
          allowAdmin: true,
          allowPatrol: false,
          allowMonPatrol: false,
          groupUid: 'grp_1',
        ),
      );

      await tester.pumpWidget(
        buildTestWidget(
          extraProviders: [
            BlocProvider<PttCubit>.value(value: pttCubit),
            BlocProvider<UserSessionCubit>.value(value: session),
          ],
        ),
      );
      await tester.pumpAndSettle();
      verifyNever(() => pttCubit.joinForGroup('grp_2'));

      session.updateSession(
        const AuthSessionEntity(
          userId: 'usr_1',
          email: 'admin@kawalo.co.id',
          name: 'Admin',
          allowAdmin: true,
          allowPatrol: false,
          allowMonPatrol: false,
          groupUid: 'grp_2',
        ),
      );
      await tester.pumpAndSettle();

      verify(() => pttCubit.joinForGroup('grp_2')).called(1);
    });

    testWidgets('never touches the PTT channel on iOS', (tester) async {
      final pttCubit = MockPttCubit();
      when(() => pttCubit.state).thenReturn(const PttInitial());
      when(() => pttCubit.joinForGroup(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          extraProviders: [
            BlocProvider<PttCubit>.value(value: pttCubit),
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(
                const AuthSessionEntity(
                  userId: 'usr_1',
                  email: 'admin@kawalo.co.id',
                  name: 'Admin',
                  allowAdmin: true,
                  allowPatrol: false,
                  allowMonPatrol: false,
                  groupUid: 'grp_1',
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => pttCubit.joinForGroup(any()));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets(
      'hides offline banner content and keeps safe area spacer when online',
      (tester) async {
        final mockConnectivity = MockConnectivityCubit();
        when(
          () => mockConnectivity.state,
        ).thenReturn(ConnectivityStatus.online);

        await tester.pumpWidget(
          buildTestWidget(connectivityCubit: mockConnectivity),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsNothing,
        );
        expect(find.text('Kembali online'), findsNothing);
        expect(find.byType(AppNavigationBar), findsOneWidget);

        final navBar = tester.widget<AppNavigationBar>(
          find.byType(AppNavigationBar),
        );
        expect(navBar.safeArea, isFalse);

        final banner = tester.widget<AppBottomOfflineBanner>(
          find.byType(AppBottomOfflineBanner),
        );
        expect(banner.keepSafeAreaWhenHidden, isTrue);
        expect(banner.isOffline, isFalse);
      },
    );
  });
}
