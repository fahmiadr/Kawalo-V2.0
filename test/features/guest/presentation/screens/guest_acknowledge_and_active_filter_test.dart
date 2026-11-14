import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockGuestCubit extends Mock implements GuestCubit {}

const _waiting = GuestItemEntity(
  id: '7',
  guestName: 'Sinta Wulandari',
  guestToUserEmail: 'host@kawalo.id',
  guestDt: '2026-11-02T08:00:00.000Z',
);

const _confirmed = GuestItemEntity(
  id: '7',
  guestName: 'Sinta Wulandari',
  guestToUserEmail: 'host@kawalo.id',
  guestDt: '2026-11-02T08:00:00.000Z',
  guestAckDt: '2026-11-02T08:05:00.000Z',
);

AuthSessionEntity _session(String email, String role) => AuthSessionEntity(
  userId: '1',
  email: email,
  name: 'User',
  role: role,
  allowAdmin: role == 'ADMIN',
  allowPatrol: role == 'GUARD',
  allowMonPatrol: false,
);

_MockGuestCubit _cubit(GuestState state) {
  final cubit = _MockGuestCubit();
  when(() => cubit.state).thenReturn(state);
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.currentGreeting).thenReturn('');
  return cubit;
}

Widget _detail(GuestItemEntity item, GuestCubit cubit, AuthSessionEntity me) {
  return BlocProvider<UserSessionCubit>.value(
    value: UserSessionCubit(me),
    child: MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: GuestDetailScreen(item: item, cubit: cubit),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const GuestItemEntity(id: '1'));
    registerFallbackValue(GuestListScope.today);
  });

  tearDown(AppSnackbar.hideCurrent);

  group('GuestDetailScreen acknowledge button', () {
    testWidgets('shows for the invited host and runs the confirm flow', (
      tester,
    ) async {
      final me = _session('host@kawalo.id', 'USER');
      final cubit = _cubit(const GuestLoaded(guests: [_waiting], lastSync: ''));
      when(
        () => cubit.acknowledgeGuest(
          any(),
          session: any(named: 'session'),
          qrUid: any(named: 'qrUid'),
        ),
      ).thenAnswer((_) async => const Right(_confirmed));

      await tester.pumpWidget(_detail(_waiting, cubit, me));
      await tester.pumpAndSettle();

      final button = find.text('Konfirmasi Kedatangan');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(AppConfirmationDialog), findsOneWidget);
      expect(find.text('Konfirmasi kedatangan?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Konfirmasi'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => cubit.acknowledgeGuest(_waiting, session: me)).called(1);
      expect(
        find.text('Kedatangan "Sinta Wulandari" berhasil dikonfirmasi.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the server error when confirming fails', (tester) async {
      final me = _session('guard@kawalo.id', 'GUARD');
      final cubit = _cubit(const GuestLoaded(guests: [_waiting], lastSync: ''));
      when(
        () => cubit.acknowledgeGuest(
          any(),
          session: any(named: 'session'),
          qrUid: any(named: 'qrUid'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ServerFailure('Kunjungan tamu sudah dikonfirmasi sebelumnya.'),
        ),
      );

      await tester.pumpWidget(_detail(_waiting, cubit, me));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Kedatangan'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Konfirmasi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Kunjungan tamu sudah dikonfirmasi sebelumnya.'),
        findsOneWidget,
      );
    });

    testWidgets('is hidden for an unrelated resident', (tester) async {
      final cubit = _cubit(const GuestLoaded(guests: [_waiting], lastSync: ''));

      await tester.pumpWidget(
        _detail(_waiting, cubit, _session('lain@kawalo.id', 'USER')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Kedatangan'), findsNothing);
    });

    testWidgets('is hidden once the visit is confirmed', (tester) async {
      final cubit = _cubit(
        const GuestLoaded(guests: [_confirmed], lastSync: ''),
      );

      await tester.pumpWidget(
        _detail(_confirmed, cubit, _session('admin@kawalo.id', 'ADMIN')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Kedatangan'), findsNothing);
    });
  });

  group('GuestScreen scope chips', () {
    Future<void> pump(WidgetTester tester, GuestCubit cubit) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          localizationsDelegates: AppTheme.localizationsDelegates,
          data: AppTheme.m3eLight(),
          home: GuestScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();
    }

    _MockGuestCubit scopedCubit(GuestState state) {
      final cubit = _cubit(state);
      when(cubit.fetchGuests).thenAnswer((_) async => AppFetchResult.success);
      when(
        () => cubit.changeScope(any()),
      ).thenAnswer((_) async => AppFetchResult.success);
      return cubit;
    }

    testWidgets('"Di lokasi" asks the cubit for on-site guests', (
      tester,
    ) async {
      final cubit = scopedCubit(
        const GuestLoaded(guests: [_waiting], lastSync: ''),
      );
      await pump(tester, cubit);

      await tester.tap(find.widgetWithText(AppChip, 'Di lokasi'));
      await tester.pumpAndSettle();

      verify(() => cubit.changeScope(GuestListScope.onSite)).called(1);
    });

    testWidgets('the selected chip does not refetch; another one does', (
      tester,
    ) async {
      final cubit = scopedCubit(
        const GuestLoaded(
          guests: [_waiting],
          lastSync: '',
          filterIsActive: true,
        ),
      );
      await pump(tester, cubit);

      await tester.tap(find.widgetWithText(AppChip, 'Di lokasi'));
      await tester.pumpAndSettle();
      verifyNever(() => cubit.changeScope(any()));

      await tester.tap(find.widgetWithText(AppChip, 'Semua'));
      await tester.pumpAndSettle();
      verify(() => cubit.changeScope(GuestListScope.all)).called(1);
    });
  });
}
