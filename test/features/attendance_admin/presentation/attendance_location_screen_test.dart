import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_location_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/attendance_location_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;

  setUp(() => repository = MockRepository());

  Future<AttendanceLocationCubit> pump(
    WidgetTester tester, {
    String role = 'ADMIN',
    AttendanceLocationEntity? location,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(
      () => repository.getLocation(),
    ).thenAnswer((_) async => Right(location ?? attendanceLocation()));
    final cubit = AttendanceLocationCubit(repository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session(role)),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AttendanceLocationScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Finder inHeader(Finder f) =>
      find.descendant(of: find.byType(AppHomeAppBar), matching: f);

  Finder inActions(Finder f) =>
      find.descendant(of: find.byType(AppPageActions), matching: f);

  bool simpanEnabled(WidgetTester tester) => tester
      .widget<AppButton>(find.widgetWithText(AppButton, 'Simpan'))
      .enabled;

  testWidgets('shows a skeleton while loading', (tester) async {
    when(() => repository.getLocation()).thenAnswer(
      (_) => Future.delayed(
        const Duration(seconds: 1),
        () => Right(attendanceLocation()),
      ),
    );
    final cubit = AttendanceLocationCubit(repository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session('ADMIN')),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AttendanceLocationScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Memuat titik absen'), findsOneWidget);
    expect(find.byType(AppPageActions), findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('an unset point asks the admin to pick one', (tester) async {
    await pump(tester);

    expect(
      find.text(
        'Belum ada titik absen. Tentukan titik agar absen hanya sah di dalam '
        'radius.',
      ),
      findsOneWidget,
    );
    expect(find.text('Belum ada titik lokasi'), findsOneWidget);
    expect(find.text('Radius absen'), findsOneWidget);
    expect(find.text('Nama titik'), findsOneWidget);
    expect(inHeader(find.text('Titik Absen')), findsOneWidget);
    expect(inHeader(find.text('Simpan')), findsNothing);
    expect(find.text('Batasi lokasi absen'), findsNothing);
  });

  testWidgets('Simpan sits at the bottom and is disabled until a point', (
    tester,
  ) async {
    final cubit = await pump(tester);

    expect(inActions(find.text('Simpan')), findsOneWidget);
    expect(simpanEnabled(tester), isFalse);

    cubit.setCoordinates(-6.2146, 106.8199);
    await tester.pump();
    await tester.pump();
    expect(simpanEnabled(tester), isTrue);

    when(
      () => repository.saveLocation(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radius: any(named: 'radius'),
        locationName: any(named: 'locationName'),
      ),
    ).thenAnswer(
      (_) async => Right(
        attendanceLocation(
          configured: true,
          name: null,
          updatedBy: 'admin@kawalo.id',
          updatedAt: '2026-11-12T01:00:00.000Z',
        ),
      ),
    );
    await tester.tap(inActions(find.text('Simpan')));
    await tester.pumpAndSettle();

    expect(find.text('Titik absen disimpan'), findsOneWidget);
    expect(
      find.textContaining('Terakhir diubah oleh admin@kawalo.id'),
      findsOneWidget,
    );
  });

  testWidgets('a configured point shows who changed it and the radius chips', (
    tester,
  ) async {
    await pump(
      tester,
      location: attendanceLocation(
        configured: true,
        updatedBy: 'admin@kawalo.id',
        updatedAt: '2026-11-12T01:00:00.000Z',
      ),
    );

    expect(find.textContaining('Belum ada titik absen'), findsNothing);
    expect(find.text('Ubah titik'), findsOneWidget);
    expect(find.text('Pos Utama'), findsOneWidget);
    expect(find.text('100 m'), findsWidgets);
    expect(
      find.textContaining('Terakhir diubah oleh admin@kawalo.id'),
      findsOneWidget,
    );
  });

  testWidgets('a failed save shows the message and keeps Simpan active', (
    tester,
  ) async {
    final cubit = await pump(tester);
    when(
      () => repository.saveLocation(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radius: any(named: 'radius'),
        locationName: any(named: 'locationName'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure('Koordinat tidak valid.', 422)),
    );
    cubit.setCoordinates(-6.2146, 106.8199);
    await tester.pump();
    await tester.pump();

    await tester.tap(inActions(find.text('Simpan')));
    await tester.pumpAndSettle();

    expect(find.text('Koordinat tidak valid.'), findsOneWidget);
    expect(simpanEnabled(tester), isTrue);
  });

  testWidgets('"Lainnya" opens the custom radius field with its error', (
    tester,
  ) async {
    final cubit = await pump(
      tester,
      location: attendanceLocation(configured: true),
    );

    await tester.tap(find.text('Lainnya'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Radius (meter) *'), findsOneWidget);

    cubit.setRadiusText('1500');
    await tester.pump();
    await tester.pump();
    expect(find.text('Radius harus 10 sampai 1000 meter.'), findsOneWidget);
  });

  testWidgets('non-admins see the point read-only without actions', (
    tester,
  ) async {
    await pump(
      tester,
      role: 'GUARD',
      location: attendanceLocation(configured: true),
    );

    expect(
      find.text('Hanya admin yang dapat mengubah titik absen.'),
      findsOneWidget,
    );
    expect(find.byType(AppPageActions), findsNothing);
    expect(find.text('Ubah titik'), findsNothing);
  });

  testWidgets('non-admins of an unset point only see the note', (tester) async {
    await pump(tester, role: 'GUARD');

    expect(
      find.text('Belum ada titik absen. Admin belum menentukannya.'),
      findsOneWidget,
    );
    expect(find.text('Belum ada titik lokasi'), findsNothing);
    expect(find.byType(AppPageActions), findsNothing);
  });

  testWidgets('a load error offers Coba lagi', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(
      () => repository.getLocation(),
    ).thenAnswer((_) async => const Left(ServerFailure('Gagal memuat.')));
    final cubit = AttendanceLocationCubit(repository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session('ADMIN')),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AttendanceLocationScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byType(AppPageActions), findsNothing);

    when(
      () => repository.getLocation(),
    ).thenAnswer((_) async => Right(attendanceLocation()));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada titik lokasi'), findsOneWidget);
  });
}
