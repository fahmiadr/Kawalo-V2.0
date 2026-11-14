import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:kawalo_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_screen_cubits.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('SplashScreen Unit & Widget Tests', () {
    testWidgets(
      'SplashScreen renders logo, subtitle, and respects wide screen bounds',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(home: SplashScreen(onInitializationComplete: () {})),
        );

        await tester.pump();
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(
          find.text('Operasional keamanan dalam satu genggaman'),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 3100));
      },
    );

    testWidgets('SplashScreen follows the dark theme of its parent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SplashScreen(onInitializationComplete: () {}),
        ),
      );

      await tester.pump();
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, equals(Brightness.dark));

      await tester.pump(const Duration(milliseconds: 3100));
    });

    testWidgets(
      'SplashScreen renders AppLoadingIndicator when loading takes longer',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SplashScreen(
              onInitialize: () =>
                  Future<void>.delayed(const Duration(milliseconds: 4000)),
              onInitializationComplete: () {},
            ),
          ),
        );

        await tester.pump();
        // Forward past 3000ms slow loading trigger
        await tester.pump(const Duration(milliseconds: 3100));
        expect(find.byType(AppLoadingIndicator), findsOneWidget);

        // Forward until completion
        await tester.pump(const Duration(milliseconds: 1000));
      },
    );

    testWidgets('SplashScreen respects reduced motion setting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              accessibleNavigation: true,
              disableAnimations: true,
            ),
            child: SplashScreen(onInitializationComplete: () {}),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(
        find.text('Operasional keamanan dalam satu genggaman'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 3100));
    });

    testWidgets(
      'navigates to OnboardingScreen when onboarding is not completed',
      (WidgetTester tester) async {
        final mockStorage = MockSecureStorageService();
        when(mockStorage.isOnboardingCompleted).thenAnswer((_) async => false);
        when(mockStorage.getAccessToken).thenAnswer((_) async => null);

        await tester.pumpWidget(
          MaterialApp(
            home: SplashScreen(
              storageService: mockStorage,
              enableOnboardingPersistence: true,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(OnboardingScreen), findsOneWidget);
      },
    );

    testWidgets('navigates to OnboardingScreen when persistence is disabled '
        '(debug/review)', (WidgetTester tester) async {
      final mockStorage = MockSecureStorageService();
      when(mockStorage.isOnboardingCompleted).thenAnswer((_) async => true);
      when(mockStorage.getAccessToken).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            storageService: mockStorage,
            enableOnboardingPersistence: false,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('navigates directly to LoginScreen when onboarding completed '
        'but not authenticated', (WidgetTester tester) async {
      final mockStorage = MockSecureStorageService();
      when(mockStorage.isOnboardingCompleted).thenAnswer((_) async => true);
      when(mockStorage.getAccessToken).thenAnswer((_) async => null);

      final mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());
      when(
        () => mockAuthBloc.stream,
      ).thenAnswer((_) => Stream.value(const Unauthenticated()));

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: MaterialApp(
            home: SplashScreen(
              storageService: mockStorage,
              enableOnboardingPersistence: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      'navigates directly to MainNavigationScreen when onboarding completed '
      'and token exists',
      (WidgetTester tester) async {
        final mockStorage = MockSecureStorageService();
        when(mockStorage.isOnboardingCompleted).thenAnswer((_) async => true);
        when(mockStorage.getAccessToken).thenAnswer((_) async => 'valid_token');

        await tester.pumpWidget(
          BlocProvider<InformationCubit>.value(
            value: createStubbedInformationCubit(),
            child: MaterialApp(
              home: SplashScreen(
                storageService: mockStorage,
                enableOnboardingPersistence: true,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(MainNavigationScreen), findsOneWidget);
      },
    );

    testWidgets(
      'navigates directly to GroupSelectionScreen when onboarding completed '
      'and GroupSelectionRequired is emitted',
      (WidgetTester tester) async {
        final mockStorage = MockSecureStorageService();
        when(mockStorage.isOnboardingCompleted).thenAnswer((_) async => true);
        when(mockStorage.getAccessToken).thenAnswer((_) async => 'valid_token');

        const tUser = UserEntity(
          id: 'u1',
          email: 'u1@k.com',
          name: 'User 1',
          groups: [
            UserGroupEntity(
              groupUid: 'g1',
              groupName: 'G1',
              allowAdmin: false,
              allowPatrol: false,
              allowMonPatrol: false,
              features: [],
            ),
            UserGroupEntity(
              groupUid: 'g2',
              groupName: 'G2',
              allowAdmin: false,
              allowPatrol: false,
              allowMonPatrol: false,
              features: [],
            ),
          ],
        );

        final mockAuthBloc = MockAuthBloc();
        when(
          () => mockAuthBloc.state,
        ).thenReturn(const GroupSelectionRequired(user: tUser));
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(const GroupSelectionRequired(user: tUser)),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp(
              home: SplashScreen(
                storageService: mockStorage,
                enableOnboardingPersistence: true,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(GroupSelectionScreen), findsOneWidget);
      },
    );
  });
}
