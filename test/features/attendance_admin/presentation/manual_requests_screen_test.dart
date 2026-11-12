import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/attendance_admin/attendance_admin_module.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/manual_requests_screen.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/manual_request_card.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockRepository repository;

  setUpAll(() => registerFallbackValue(ManualRequestStatus.pending));

  setUp(() => repository = MockRepository());

  Future<ManualRequestsCubit> pump(
    WidgetTester tester, {
    required String role,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = ManualRequestsCubit(repository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session(role)),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: ManualRequestsScreen(
            module: AttendanceAdminModule(apiClient: MockApiClient()),
            cubit: cubit,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('admin sees the pending requests and can switch tabs', (
    tester,
  ) async {
    when(
      () => repository.getManualRequests(
        status: ManualRequestStatus.pending,
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => Right([manualRequest()]));
    when(
      () => repository.getManualRequests(
        status: ManualRequestStatus.rejected,
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Right([]));

    await pump(tester, role: 'ADMIN');

    expect(find.byType(ManualRequestCard), findsOneWidget);
    expect(find.text('Siti Rahmawati'), findsOneWidget);
    for (final label in ['Menunggu', 'Disetujui', 'Ditolak']) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    await tester.tap(find.widgetWithText(Tab, 'Ditolak'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualRequestCard), findsNothing);
    expect(find.text('Belum ada permintaan yang ditolak.'), findsOneWidget);
  });

  testWidgets('non-admin gets an explanation and no request is fetched', (
    tester,
  ) async {
    await pump(tester, role: 'GUARD');

    expect(find.text('Khusus administrator'), findsOneWidget);
    verifyNever(
      () => repository.getManualRequests(
        status: any(named: 'status'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );
  });
}
