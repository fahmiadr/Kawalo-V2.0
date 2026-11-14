import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';

class MockGuestCubit extends Mock implements GuestCubit {}

class MockGuestFormCubit extends Mock implements GuestFormCubit {}

const _admin = AuthSessionEntity(
  userId: '1',
  email: 'admin@kawalo.id',
  name: 'Admin',
  role: 'ADMIN',
  allowAdmin: true,
  allowPatrol: true,
  allowMonPatrol: true,
);

const _guard = AuthSessionEntity(
  userId: '2',
  email: 'guard@kawalo.id',
  name: 'Guard',
  role: 'GUARD',
  allowAdmin: false,
  allowPatrol: true,
  allowMonPatrol: false,
);

const _resident = AuthSessionEntity(
  userId: '3',
  email: 'warga@kawalo.id',
  name: 'Warga',
  role: 'USER',
  allowAdmin: false,
  allowPatrol: false,
  allowMonPatrol: false,
);

/// Acknowledged, still on site.
const GuestItemEntity _onSite = GuestFixtures.sampleWaitingGuest;
const GuestItemEntity _exited = GuestFixtures.sampleExitedGuest;

/// Not acknowledged yet.
const GuestItemEntity _unconfirmed = GuestFixtures.sampleDetailTamu2Guest;

MockGuestCubit _cubitWith(GuestItemEntity item) {
  final cubit = MockGuestCubit();
  when(() => cubit.state).thenReturn(GuestLoaded(guests: [item], lastSync: ''));
  when(() => cubit.stream).thenAnswer((_) => const Stream<GuestState>.empty());
  when(() => cubit.currentGreeting).thenReturn('');
  return cubit;
}

Widget _app(
  GuestItemEntity item, {
  AuthSessionEntity? session,
  GuestCubit? cubit,
  ConnectivityStatus connectivity = ConnectivityStatus.online,
  GuestFormCubit? formCubit,
}) {
  return MultiBlocProvider(
    providers: [
      if (session != null)
        BlocProvider<UserSessionCubit>.value(value: UserSessionCubit(session)),
      BlocProvider<ConnectivityCubit>.value(
        value: ConnectivityCubit(initialState: connectivity, autoStart: false),
      ),
      if (formCubit != null)
        BlocProvider<GuestFormCubit>.value(value: formCubit),
    ],
    child: M3EMaterialApp(
      localizationsDelegates: AppTheme.localizationsDelegates,
      data: AppTheme.m3eLight(),
      home: GuestDetailScreen(item: item, cubit: cubit),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const GuestItemEntity(id: '1'));
  });

  tearDown(AppSnackbar.hideCurrent);

  group('GuestDetailScreen content', () {
    testWidgets('shows name, type, presence, times and details', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_exited, session: _admin));
      await tester.pumpAndSettle();

      expect(find.text('Bambang Sudarsono'), findsOneWidget);
      expect(find.text('Visitor'), findsOneWidget);
      final pill = tester.widget<AppStatusPill>(find.byType(AppStatusPill));
      expect(pill.label, startsWith('Keluar '));
      for (final label in ['Masuk', 'Dikonfirmasi', 'Keluar', 'Tujuan']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Wisnu wijayadi - Veranda'), findsOneWidget);
      expect(find.text('KTP CT 10713'), findsOneWidget);
      expect(find.text('B 2706 SBX'), findsOneWidget);
      expect(find.text('Check-out oleh'), findsOneWidget);
      expect(find.text('QR-VER-2706-SBX'), findsOneWidget);
    });

    testWidgets('shows the typed host name', (tester) async {
      const typedHost = GuestItemEntity(
        id: '7',
        guestName: 'Tamu Teks',
        guestToName: 'Pak Slamet',
      );
      await tester.pumpWidget(_app(typedHost));
      await tester.pumpAndSettle();

      expect(find.text('Bertemu'), findsOneWidget);
      expect(find.text('Pak Slamet'), findsOneWidget);
    });

    testWidgets('unconfirmed guest shows "Belum dikonfirmasi"', (tester) async {
      await tester.pumpWidget(_app(_unconfirmed));
      await tester.pumpAndSettle();

      final pill = tester.widget<AppStatusPill>(find.byType(AppStatusPill));
      expect(pill.label, 'Belum dikonfirmasi');
      expect(pill.kind, AppStatusKind.warn);
    });

    testWidgets('copies the QR code', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(_app(_exited));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QR-VER-2706-SBX'));
      await tester.pumpAndSettle();

      expect(copied, 'QR-VER-2706-SBX');
      expect(find.text('Kode akses QR disalin.'), findsOneWidget);
    });

    testWidgets('renders under 200% text scaling', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(_onSite, session: _admin));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('navigateToGuestDetailScreen pushes the screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          localizationsDelegates: AppTheme.localizationsDelegates,
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    navigateToGuestDetailScreen(context, item: _exited),
                child: const Text('Buka Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Detail'));
      await tester.pumpAndSettle();
      expect(find.byType(GuestDetailScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GuestDetailScreen), findsNothing);
    });

    testWidgets('pull-to-refresh refreshes the list cubit', (tester) async {
      final cubit = _cubitWith(_exited);
      when(cubit.refreshGuests).thenAnswer((_) async => AppFetchResult.success);

      await tester.pumpWidget(_app(_exited, cubit: cubit));
      await tester.pumpAndSettle();
      await tester.fling(find.text('Masuk'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(cubit.refreshGuests).called(1);
      expect(find.text('Data tamu berhasil diperbarui.'), findsOneWidget);
    });
  });

  group('GuestDetailScreen bottom action', () {
    testWidgets('unacknowledged guest offers "Konfirmasi Kedatangan"', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_unconfirmed, session: _guard));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Kedatangan'), findsOneWidget);
      expect(find.text('Check-out Tamu'), findsNothing);
    });

    testWidgets('acknowledged guest offers check-out with a confirm dialog', (
      tester,
    ) async {
      final cubit = _cubitWith(_onSite);
      final completer = Completer<Either<Failure, GuestItemEntity>>();
      when(
        () => cubit.checkoutGuest(
          any(),
          session: any(named: 'session'),
          qrUid: any(named: 'qrUid'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_app(_onSite, session: _guard, cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Kedatangan'), findsNothing);
      await tester.tap(find.text('Check-out Tamu'));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsOneWidget);
      expect(find.text('Check-out Reni Marsiti?'), findsOneWidget);
      expect(find.textContaining('Jam keluar dicatat'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Check-out'),
        ),
      );
      await tester.pump();
      final button = tester.widget<AppTaskButton>(
        find.widgetWithText(AppTaskButton, 'Check-out Tamu'),
      );
      expect(button.isLoading, isTrue);

      completer.complete(
        const Right(
          GuestItemEntity(
            id: '2',
            guestName: 'Reni Marsiti',
            guestOutDt: '2026-09-28T15:00:00.000Z',
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => cubit.checkoutGuest(_onSite, session: _guard)).called(1);
      expect(find.textContaining('check-out pukul'), findsOneWidget);
    });

    testWidgets('checked-out guest has no bottom action', (tester) async {
      await tester.pumpWidget(_app(_exited, session: _admin));
      await tester.pumpAndSettle();

      expect(find.byType(AppTaskButton), findsNothing);
    });

    testWidgets('residents get no action, edit or delete', (tester) async {
      await tester.pumpWidget(_app(_onSite, session: _resident));
      await tester.pumpAndSettle();

      expect(find.byType(AppTaskButton), findsNothing);
      expect(find.byTooltip('Ubah data tamu'), findsNothing);
      expect(find.byTooltip('Hapus data tamu'), findsNothing);
    });

    testWidgets('offline disables the action and shows the banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _onSite,
          session: _admin,
          connectivity: ConnectivityStatus.offline,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<AppTaskButton>(
        find.widgetWithText(AppTaskButton, 'Check-out Tamu'),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
      final edit = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.edit_outlined),
      );
      expect(edit.onPressed, isNull);
    });
  });

  group('GuestDetailScreen top bar', () {
    testWidgets('edit opens the guest form', (tester) async {
      final formCubit = MockGuestFormCubit();
      when(() => formCubit.state).thenReturn(
        const GuestFormState(
          mode: GuestFormMode.update,
          name: 'Bambang Sudarsono',
        ),
      );
      when(
        () => formCubit.stream,
      ).thenAnswer((_) => const Stream<GuestFormState>.empty());

      await tester.pumpWidget(
        _app(
          _exited,
          session: _admin,
          cubit: _cubitWith(_exited),
          formCubit: formCubit,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ubah data tamu'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestFormDialog), findsOneWidget);
      expect(find.text('Ubah Data Tamu'), findsOneWidget);
    });

    testWidgets('delete confirms, shows the overlay and pops', (tester) async {
      final cubit = _cubitWith(_exited);
      final completer = Completer<Either<Failure, void>>();
      when(
        () => cubit.deleteGuest(any(), session: any(named: 'session')),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_app(_exited, session: _admin, cubit: cubit));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus data tamu'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus data tamu?'), findsOneWidget);
      expect(
        find.text(
          'Data tamu "Bambang Sudarsono" akan dihapus secara permanen.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Hapus'));
      await tester.pump();
      expect(
        tester
            .widget<AppLoadingOverlay>(find.byType(AppLoadingOverlay))
            .isLoading,
        isTrue,
      );

      completer.complete(const Right(null));
      await tester.pumpAndSettle();

      verify(() => cubit.deleteGuest(_exited, session: _admin)).called(1);
      expect(find.text('Data tamu berhasil dihapus.'), findsOneWidget);
    });

    testWidgets('a failed delete keeps the screen and shows the error', (
      tester,
    ) async {
      final cubit = _cubitWith(_exited);
      when(
        () => cubit.deleteGuest(any(), session: any(named: 'session')),
      ).thenAnswer((_) async => const Left(ServerFailure('Gagal menghapus.')));

      await tester.pumpWidget(_app(_exited, session: _admin, cubit: cubit));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus data tamu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal menghapus.'), findsOneWidget);
      expect(find.byType(GuestDetailScreen), findsOneWidget);
    });
  });
}
