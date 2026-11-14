import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/home/home_module.dart';
import 'package:kawalo_mobile/features/home/presentation/utils/home_greeting_helper.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityStatus>
    implements ConnectivityCubit {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockApiClient extends Mock implements ApiClient {}

class MockStorage extends Mock implements SecureStorageService {}

const _session = AuthSessionEntity(
  userId: 'usr_1',
  email: 'admin@kawalo.co.id',
  name: 'AHMAD ZAKI FAUZAN',
  role: 'ADMIN',
  groupUid: 'grp_1',
  allowAdmin: true,
  allowPatrol: false,
  allowMonPatrol: false,
);

/// The bar item (not the card title) whose label is [label] is selected.
Finder _selectedBarItem(String label) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.selected == true &&
      w.properties.label == label,
);

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
    ConnectivityCubit? connectivityCubit,
    HomeModule? homeModule,
    AuthSessionEntity? session,
  }) {
    final mockAuthRepository = MockAuthRepository();
    when(
      mockAuthRepository.getCurrentUser,
    ).thenAnswer((_) async => const Right(testUser));
    when(
      mockAuthRepository.getActiveSession,
    ).thenAnswer((_) async => const Right(null));

    Widget child = MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            loginUseCase: MockLoginUseCase(),
            authRepository: mockAuthRepository,
            logoutUseCase: MockLogoutUseCase(),
          )..add(const AuthCheckRequested()),
        ),
        if (session != null)
          BlocProvider<UserSessionCubit>(
            create: (_) => UserSessionCubit(session),
          ),
        if (connectivityCubit != null)
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
      ],
      child: const MainNavigationScreen(),
    );
    if (homeModule != null) {
      child = RepositoryProvider<HomeModule>.value(
        value: homeModule,
        child: child,
      );
    }
    return MaterialApp(theme: AppTheme.lightThemeData(), home: child);
  }

  group('MainNavigationScreen', () {
    // Same snackbar text in two tests would be swallowed by the debounce.
    setUp(AppSnackbar.hideCurrent);

    testWidgets('header greets with the short greeting and first name', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(HomeGreetingHelper.formatShort(name: testUser.name)),
        findsOneWidget,
      );
    });

    testWidgets('default deck: SOS, Insiden, Patroli, Lainnya (no PTT cubit '
        'means no PTT card)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      for (final label in ['SOS', 'Insiden', 'Patroli', 'Lainnya']) {
        expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
      }
      expect(find.bySemanticsLabel('PTT'), findsNothing);
      expect(_selectedBarItem('SOS'), findsOneWidget);
      expect(find.text('Darurat'), findsOneWidget);
    });

    testWidgets('tapping a bar item moves the deck to that card', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Lainnya').last);
      await tester.pumpAndSettle();

      expect(_selectedBarItem('Lainnya'), findsOneWidget);
      expect(find.text('FITUR LAIN'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);
      expect(find.text('Atur Beranda'), findsOneWidget);
      // No arrow past the last card.
      expect(find.bySemanticsLabel(RegExp('^Kartu berikutnya')), findsNothing);
    });

    testWidgets('swiping moves the deck and the bar follows', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
      await tester.pumpAndSettle();

      expect(_selectedBarItem('Insiden'), findsOneWidget);
      expect(_selectedBarItem('SOS'), findsNothing);
    });

    testWidgets('arrows and a tap on the peeking card move the deck', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('^Kartu sebelumnya')), findsNothing);
      await tester.tap(find.bySemanticsLabel('Kartu berikutnya: Insiden'));
      await tester.pumpAndSettle();
      expect(_selectedBarItem('Insiden'), findsOneWidget);

      final deck = tester.getRect(find.byType(PageView));
      await tester.tapAt(Offset(deck.right - 8, deck.top + 40));
      await tester.pumpAndSettle();
      expect(_selectedBarItem('Patroli'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Kartu sebelumnya: Insiden'));
      await tester.pumpAndSettle();
      expect(_selectedBarItem('Insiden'), findsOneWidget);
    });

    testWidgets('SOS looks normal and says Fitur dalam pengerjaan', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SEGERA HADIR'), findsNothing);
      await tester.tap(find.text('Tahan 3 detik'));
      await tester.pump();
      expect(find.text('Fitur dalam pengerjaan'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });

    testWidgets('admins get Kelola instead of Personil in Lainnya', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(session: _session));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Lainnya').last);
      await tester.pumpAndSettle();

      expect(find.text('Kelola'), findsOneWidget);
      expect(find.text('Personil'), findsNothing);
    });

    testWidgets('guards get Personil', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          session: const AuthSessionEntity(
            userId: 'usr_2',
            email: 'guard@kawalo.co.id',
            name: 'Budi',
            role: 'GUARD',
            groupUid: 'grp_1',
            allowAdmin: false,
            allowPatrol: false,
            allowMonPatrol: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Lainnya').last);
      await tester.pumpAndSettle();

      expect(find.text('Personil'), findsOneWidget);
      expect(find.text('Kelola'), findsNothing);
    });

    testWidgets('the saved layout orders the deck', (tester) async {
      final api = MockApiClient();
      final storage = MockStorage();
      when(() => storage.getHomeLayout(any())).thenAnswer((_) async => null);
      when(() => storage.saveHomeLayout(any(), any())).thenAnswer((_) async {});
      when(() => api.get('/v1/me/home-layout')).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'order': ['inc', 'sos', 'gst', 'pat'],
            'hidden': ['pat'],
            'is_default': false,
          },
        },
      );

      await tester.pumpWidget(
        buildTestWidget(
          session: _session,
          homeModule: HomeModule(apiClient: api, storage: storage),
        ),
      );
      await tester.pumpAndSettle();

      expect(_selectedBarItem('Insiden'), findsOneWidget);
      expect(find.bySemanticsLabel('Buku Tamu'), findsWidgets);
      expect(find.bySemanticsLabel('Patroli'), findsNothing);
      final x = [
        for (final label in ['Insiden', 'SOS', 'Buku Tamu', 'Lainnya'])
          tester.getCenter(find.bySemanticsLabel(label).last).dx,
      ];
      expect(x, orderedEquals([...x]..sort()));
    });

    testWidgets('renders the offline banner when offline', (tester) async {
      final mockConnectivity = MockConnectivityCubit();
      when(() => mockConnectivity.state).thenReturn(ConnectivityStatus.offline);

      await tester.pumpWidget(
        buildTestWidget(connectivityCubit: mockConnectivity),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsOneWidget,
      );
    });

    testWidgets('notification bell says the feature is in progress', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Notifikasi'));
      await tester.pump();

      expect(find.text('Fitur dalam pengerjaan'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });
}
