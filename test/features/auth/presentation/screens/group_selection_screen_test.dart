import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_card.dart';
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

  final lanjut = find.widgetWithText(AppTaskButton, 'Lanjut');

  bool isSelected(WidgetTester tester, String uid) =>
      tester.widget<GroupCard>(find.byKey(ValueKey(uid))).isSelected;

  testWidgets('renders every group with owner and role, CTA pinned', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        mockLogin: MockLoginUseCase(),
        mockSwitch: MockSwitchGroupUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih grup'), findsOneWidget);
    expect(
      find.text(
        'Akun Anda terdaftar di 2 grup. Pilih grup untuk bertugas hari ini.',
      ),
      findsOneWidget,
    );
    expect(find.text('PT Kawalo Security'), findsOneWidget);
    expect(find.text('PT Maju Bersama'), findsOneWidget);
    expect(find.text('Pemilik: Budi Santoso'), findsOneWidget);
    expect(find.text('Pemilik: Siti Rahma'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('GUARD'), findsOneWidget);
    expect(lanjut, findsOneWidget);
    expect(tester.getRect(lanjut).bottom, lessThanOrEqualTo(600));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'GroupCard_GRP-001');
  });

  testWidgets(
    'submits SwitchGroupSubmitted for the tapped group and goes to the shell',
    (tester) async {
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
          mockLogin: MockLoginUseCase(),
          mockSwitch: mockSwitch,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PT Maju Bersama'));
      await tester.pumpAndSettle();
      await tester.tap(lanjut);
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

  testWidgets('Lanjut shows a spinner while switching', (tester) async {
    final mockSwitch = MockSwitchGroupUseCase();
    final completer = Completer<Either<Failure, UserEntity>>();
    when(() => mockSwitch(any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      createWidgetUnderTest(
        mockLogin: MockLoginUseCase(),
        mockSwitch: mockSwitch,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(lanjut);
    await tester.pump();

    expect(tester.widget<AppTaskButton>(lanjut).isLoading, isTrue);

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
  });

  testWidgets('keyboard Enter on a focused group selects it', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        mockLogin: MockLoginUseCase(),
        mockSwitch: MockSwitchGroupUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    FocusManager.instance.rootScope.descendants
        .firstWhere((n) => n.debugLabel == 'GroupCard_GRP-002')
        .requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(isSelected(tester, 'GRP-002'), isTrue);
    expect(isSelected(tester, 'GRP-001'), isFalse);
  });
}
