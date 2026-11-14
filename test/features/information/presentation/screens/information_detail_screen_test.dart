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
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_detail_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_file_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_location_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationCubit extends Mock implements InformationCubit {}

class MockInformationFormCubit extends Mock implements InformationFormCubit {}

const _admin = AuthSessionEntity(
  userId: '1',
  email: 'admin@kawalo.id',
  name: 'Admin',
  role: 'ADMIN',
  allowAdmin: true,
  allowPatrol: true,
  allowMonPatrol: true,
);

const _otherGuard = AuthSessionEntity(
  userId: '2',
  email: 'lain@kawalo.id',
  name: 'Guard',
  role: 'GUARD',
  allowAdmin: false,
  allowPatrol: true,
  allowMonPatrol: false,
);

const _event = InformationItemEntity(
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
  glat: -6.2,
  glong: 106.816666,
);

const _withMedia = InformationItemEntity(
  id: '102',
  photos: ['https://example.com/photo1.jpg'],
  title: 'Laporan Kerusakan Lampu Jalan',
  userName: 'Agus Wijaya',
  feedDt: '10 Sep 2026 10:00',
  feedType: 'INCIDENT',
  feedFile: 'https://example.com/laporan_insiden.pdf',
);

MockInformationCubit _cubitWith(InformationItemEntity item) {
  final cubit = MockInformationCubit();
  when(
    () => cubit.state,
  ).thenReturn(InformationLoaded(information: [item], lastSync: ''));
  when(
    () => cubit.stream,
  ).thenAnswer((_) => const Stream<InformationState>.empty());
  when(() => cubit.currentGreeting).thenReturn('');
  return cubit;
}

Widget _app(
  InformationItemEntity item, {
  AuthSessionEntity? session,
  InformationCubit? cubit,
  ConnectivityStatus connectivity = ConnectivityStatus.online,
  InformationFormCubit? formCubit,
}) {
  return MultiBlocProvider(
    providers: [
      if (session != null)
        BlocProvider<UserSessionCubit>.value(value: UserSessionCubit(session)),
      BlocProvider<ConnectivityCubit>.value(
        value: ConnectivityCubit(initialState: connectivity, autoStart: false),
      ),
      if (formCubit != null)
        BlocProvider<InformationFormCubit>.value(value: formCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: InformationDetailScreen(item: item, cubit: cubit),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const InformationItemEntity(id: '1', photos: []));
  });

  tearDown(AppSnackbar.hideCurrent);

  testWidgets('shows category, title, author, schedule, text and location', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_event));
    await tester.pumpAndSettle();

    expect(find.text('Informasi'), findsOneWidget);
    expect(
      tester.widget<AppStatusPill>(find.byType(AppStatusPill)).label,
      'Acara',
    );
    expect(find.text('Pelatihan Tanggap Darurat'), findsOneWidget);
    expect(find.text('Budi Santoso · 9 Sep 2026 14.20'), findsOneWidget);
    expect(find.text('Jadwal acara'), findsOneWidget);
    expect(
      find.text('Simulasi latihan kebakaran bersama damkar.'),
      findsOneWidget,
    );
    expect(find.byType(InformationDetailLocationCard), findsOneWidget);
    expect(find.byType(InformationDetailFileSection), findsNothing);
    expect(find.byType(AppImageCollage), findsNothing);
  });

  testWidgets('shows photos and the attachment when present', (tester) async {
    await tester.pumpWidget(_app(_withMedia));
    await tester.pumpAndSettle();

    expect(find.byType(AppImageCollage), findsOneWidget);
    expect(find.byType(InformationDetailFileSection), findsOneWidget);
    expect(find.text('Jadwal acara'), findsNothing);
  });

  testWidgets('admin gets edit and delete in the top bar, no bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_event, session: _admin));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ubah informasi'), findsOneWidget);
    expect(find.byTooltip('Hapus informasi'), findsOneWidget);
    expect(find.text('Tambah Informasi'), findsNothing);
  });

  testWidgets("a guard sees no actions on someone else's post", (tester) async {
    await tester.pumpWidget(_app(_event, session: _otherGuard));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ubah informasi'), findsNothing);
    expect(find.byTooltip('Hapus informasi'), findsNothing);
  });

  testWidgets('edit opens the information form', (tester) async {
    final formCubit = MockInformationFormCubit();
    when(() => formCubit.state).thenReturn(
      const InformationFormState(
        mode: InformationFormMode.update,
        title: 'Pelatihan Tanggap Darurat',
      ),
    );
    when(
      () => formCubit.stream,
    ).thenAnswer((_) => const Stream<InformationFormState>.empty());

    await tester.pumpWidget(
      _app(
        _event,
        session: _admin,
        cubit: _cubitWith(_event),
        formCubit: formCubit,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ubah informasi'));
    await tester.pumpAndSettle();

    expect(find.byType(InformationFormDialog), findsOneWidget);
    expect(find.text('Ubah Informasi'), findsOneWidget);
  });

  testWidgets('delete confirms, shows the overlay and calls the cubit', (
    tester,
  ) async {
    final cubit = _cubitWith(_event);
    final completer = Completer<Either<Failure, void>>();
    when(
      () => cubit.deleteInformation(any(), session: any(named: 'session')),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_app(_event, session: _admin, cubit: cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus informasi'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus informasi?'), findsOneWidget);
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

    verify(() => cubit.deleteInformation(_event, session: _admin)).called(1);
    expect(find.text('Informasi berhasil dihapus.'), findsOneWidget);
  });

  testWidgets('offline disables the actions and shows the banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_event, session: _admin, connectivity: ConnectivityStatus.offline),
    );
    await tester.pumpAndSettle();

    for (final icon in [Icons.edit_outlined, Icons.delete_outline_rounded]) {
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, icon),
      );
      expect(button.onPressed, isNull);
    }
    expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
  });
}
