import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_screen_cubits.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSwitchGroupUseCase extends Mock implements SwitchGroupUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SwitchGroupParams(groupUid: ''));
  });

  const tUser = UserEntity(
    id: 'user_123',
    email: 'admin@kawalo.co.id',
    name: 'Super Admin',
    groups: [
      UserGroupEntity(
        groupUid: 'GRP-001',
        groupName: 'PT Kawalo Security',
        groupOwner: 'Budi Santoso',
        category: 'ADMIN',
        groupStatus: 'PAID',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: false,
        features: [],
      ),
      UserGroupEntity(
        groupUid: 'GRP-002',
        groupName: 'PT Maju Bersama',
        groupOwner: 'Siti Rahma',
        category: 'GUARD',
        groupStatus: 'CLIENT',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: true,
        features: [],
      ),
    ],
    activeGroup: UserGroupEntity(
      groupUid: 'GRP-001',
      groupName: 'PT Kawalo Security',
      groupOwner: 'Budi Santoso',
      category: 'ADMIN',
      groupStatus: 'PAID',
      allowAdmin: true,
      allowPatrol: true,
      allowMonPatrol: false,
      features: [],
    ),
  );

  Widget createWidgetUnderTest({
    required MockLoginUseCase mockLogin,
    required MockSwitchGroupUseCase mockSwitch,
    MockLogoutUseCase? mockLogout,
  }) {
    return BlocProvider<InformationCubit>.value(
      value: createStubbedInformationCubit(),
      child: M3EMaterialApp(
        data: AppTheme.m3eLight(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            loginUseCase: mockLogin,
            switchGroupUseCase: mockSwitch,
            logoutUseCase: mockLogout,
          ),
          child: const GroupSelectionScreen(user: tUser),
        ),
      ),
    );
  }

  testWidgets(
    'GroupSelectionScreen renders all groups with owners, status, permissions',
    (WidgetTester tester) async {
      final mockLogin = MockLoginUseCase();
      final mockSwitch = MockSwitchGroupUseCase();

      await tester.pumpWidget(
        createWidgetUnderTest(
          mockLogin: mockLogin,
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pilih grup'), findsOneWidget);
      expect(find.text('PT Kawalo Security'), findsOneWidget);
      expect(find.text('PT Maju Bersama'), findsOneWidget);
      expect(find.text('Pemilik: Budi Santoso'), findsOneWidget);
      expect(find.text('Pemilik: Siti Rahma'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('GUARD'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('CLIENT'), findsOneWidget);

      // Active group GRP-001 starts expanded
      expect(find.text('Admin: Aktif'), findsOneWidget);
      expect(find.text('Patroli: Aktif'), findsOneWidget);
      expect(find.text('Monitor patroli: Nonaktif'), findsOneWidget);

      final buttonFinder = find.text('Lanjutkan ke beranda');
      await tester.ensureVisible(buttonFinder);
      expect(buttonFinder, findsOneWidget);
    },
  );

  testWidgets(
    'tapping an unselected group expands it and shows its permissions',
    (WidgetTester tester) async {
      final mockLogin = MockLoginUseCase();
      final mockSwitch = MockSwitchGroupUseCase();

      await tester.pumpWidget(
        createWidgetUnderTest(
          mockLogin: mockLogin,
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      // Before selecting GRP-002, permissions ('Monitor patroli: Aktif') hidden
      expect(find.text('Monitor patroli: Aktif'), findsNothing);

      // Tap second group
      await tester.tap(find.text('PT Maju Bersama'));
      await tester.pumpAndSettle();

      // Now GRP-002 is expanded and shows its permissions
      expect(find.text('Monitor patroli: Aktif'), findsOneWidget);
      expect(find.text('Admin: Nonaktif'), findsOneWidget);
    },
  );

  testWidgets(
    'submits SwitchGroupSubmitted when a group is selected and CTA tapped',
    (WidgetTester tester) async {
      final mockLogin = MockLoginUseCase();
      final mockSwitch = MockSwitchGroupUseCase();

      when(() => mockSwitch(any())).thenAnswer(
        (_) async => const Right(
          UserEntity(
            id: 'user_123',
            email: 'admin@kawalo.co.id',
            name: 'Super Admin',
            groups: [],
            activeGroup: UserGroupEntity(
              groupUid: 'GRP-002',
              groupName: 'PT Maju Bersama',
              groupOwner: 'Siti Rahma',
              category: 'GUARD',
              allowAdmin: false,
              allowPatrol: true,
              allowMonPatrol: false,
              features: [],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          mockLogin: mockLogin,
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      // Tap second group card
      await tester.tap(find.text('PT Maju Bersama'));
      await tester.pumpAndSettle();

      // Ensure button is visible before tapping
      final buttonFinder = find.text('Lanjutkan ke beranda');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      verify(
        () => mockSwitch(
          any(
            that: isA<SwitchGroupParams>().having(
              (p) => p.groupUid,
              'groupUid',
              'GRP-002',
            ),
          ),
        ),
      ).called(1);

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    },
  );

  testWidgets(
    'shows modal scrim overlay with AppLoadingIndicator (contained variant) '
    'while loading',
    (WidgetTester tester) async {
      final mockLogin = MockLoginUseCase();
      final mockSwitch = MockSwitchGroupUseCase();
      final completer = Completer<Either<Failure, UserEntity>>();

      when(() => mockSwitch(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        createWidgetUnderTest(
          mockLogin: mockLogin,
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.text('Lanjutkan ke beranda');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(buttonFinder);
      await tester.pump();

      // Modal overlay is displayed with contained AppLoadingIndicator
      final indicatorFinder = find.byType(AppLoadingIndicator);
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<AppLoadingIndicator>(indicatorFinder);
      expect(indicator.variant, AppLoadingIndicatorVariant.contained);
      expect(indicator.semanticLabel, 'Menyiapkan grup');

      // Complete future to settle
      completer.complete(
        const Right(
          UserEntity(
            id: 'user_123',
            email: 'admin@kawalo.co.id',
            name: 'Super Admin',
            groups: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'initial focus is requested on active group and CTA is always visible',
    (WidgetTester tester) async {
      final mockLogin = MockLoginUseCase();
      final mockSwitch = MockSwitchGroupUseCase();

      await tester.pumpWidget(
        createWidgetUnderTest(
          mockLogin: mockLogin,
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      // Active group GRP-001 has focus
      final primaryFocus = FocusManager.instance.primaryFocus;
      expect(primaryFocus?.debugLabel, 'GroupCard_GRP-001');

      // The CTA button is immediately visible without needing to scroll
      final buttonFinder =
          find.widgetWithText(AppButton, 'Lanjutkan ke beranda');
      expect(buttonFinder, findsOneWidget);
      expect(
        tester.getRect(buttonFinder).bottom,
        lessThanOrEqualTo(600),
      );
    },
  );

  testWidgets(
    'keyboard Enter key on focused unselected group triggers selection',
    (WidgetTester tester) async {
      final mockLogin = MockLoginUseCase();
      final mockSwitch = MockSwitchGroupUseCase();

      await tester.pumpWidget(
        createWidgetUnderTest(
          mockLogin: mockLogin,
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      final secondCardFinder = find.byWidgetPredicate(
        (w) => w is Focus && w.debugLabel == 'GroupCard_GRP-002',
      );
      expect(secondCardFinder, findsOneWidget);

      (tester.widget(secondCardFinder) as Focus).focusNode?.requestFocus();
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'GroupCard_GRP-002',
      );

      // Send Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // GRP-002 is now selected (its permissions are expanded)
      expect(find.text('Monitor patroli: Aktif'), findsOneWidget);
    },
  );
}
