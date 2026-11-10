import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/routes/app_route_observer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/mock_screen_cubits.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  const user = UserEntity(
    id: 'u1',
    email: 'admin@kawalo.co.id',
    name: 'Super Admin',
    groups: [],
  );

  late AppRouteObserver observer;
  late GlobalKey<NavigatorState> navKey;
  late AppRouter router;

  setUp(() {
    observer = AppRouteObserver();
    navKey = GlobalKey<NavigatorState>();
    router = AppRouter(() => navKey.currentState!);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      BlocProvider<InformationCubit>.value(
        value: createStubbedInformationCubit(),
        child: BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(loginUseCase: MockLoginUseCase()),
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            navigatorKey: navKey,
            navigatorObservers: [observer],
            home: const SizedBox(),
          ),
        ),
      ),
    );
    // Something extra under the home route, to prove the reset clears it all.
    navKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/stale'),
        builder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectOnlyRoute(String name) {
    expect(observer.currentRouteName, name);
    expect(observer.isOpen('/stale'), isFalse);
    expect(observer.isOpen('/'), isFalse);
    expect(navKey.currentState!.canPop(), isFalse);
  }

  testWidgets('toLogin clears the stack and shows LoginScreen', (tester) async {
    await pumpApp(tester);

    unawaited(router.toLogin(sessionExpiredMessage: 'Sesi berakhir'));
    await tester.pumpAndSettle();

    expectOnlyRoute(AppRouteNames.login);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sesi berakhir'), findsOneWidget);
  });

  testWidgets('toMain clears the stack and shows MainNavigationScreen', (
    tester,
  ) async {
    await pumpApp(tester);

    unawaited(router.toMain());
    await tester.pumpAndSettle();

    expectOnlyRoute(AppRouteNames.main);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('toGroupSelection clears the stack and passes the user', (
    tester,
  ) async {
    await pumpApp(tester);

    unawaited(router.toGroupSelection(user));
    await tester.pumpAndSettle();

    expectOnlyRoute(AppRouteNames.groupSelection);
    expect(
      tester
          .widget<GroupSelectionScreen>(find.byType(GroupSelectionScreen))
          .user,
      user,
    );
  });

  testWidgets('pushGroupSelection keeps the stack and allows cancelling', (
    tester,
  ) async {
    await pumpApp(tester);

    unawaited(router.pushGroupSelection(user));
    await tester.pumpAndSettle();

    final screen = tester.widget<GroupSelectionScreen>(
      find.byType(GroupSelectionScreen),
    );
    expect(screen.allowCancel, isTrue);
    expect(observer.currentRouteName, AppRouteNames.groupSelection);

    navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(GroupSelectionScreen), findsNothing);
  });

  testWidgets('toOnboarding clears the stack and shows OnboardingScreen', (
    tester,
  ) async {
    await pumpApp(tester);

    unawaited(router.toOnboarding());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expectOnlyRoute(AppRouteNames.onboarding);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Dispose the screen so its carousel timers do not outlive the test.
    unawaited(router.toLogin());
    await tester.pumpAndSettle();
  });

  testWidgets('AppRouter.of resolves the nearest Navigator', (tester) async {
    late AppRouter fromContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            fromContext = AppRouter.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    // Not pushing a real screen here; just verify the navigator is reachable.
    expect(observer.currentRouteName, '/');
    expect(fromContext, isA<AppRouter>());
  });
}
