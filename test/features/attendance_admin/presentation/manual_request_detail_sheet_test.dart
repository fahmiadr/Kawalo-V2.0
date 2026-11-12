import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/face_photos_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/manual_request_detail_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;
  late ManualRequestsCubit cubit;

  setUp(() {
    repository = MockRepository();
    cubit = ManualRequestsCubit(repository: repository);
  });
  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester,
    ManualRequestEntity request, {
    String role = 'ADMIN',
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session(role)),
        child: M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: ManualRequestDetailSheet(
              request: request,
              cubit: cubit,
              createFacePhotosCubit: (email) =>
                  FacePhotosCubit(repository: repository, email: email),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder inDialog(String text) => find.descendant(
    of: find.byType(AppConfirmationDialog),
    matching: find.text(text),
  );

  testWidgets('approval asks for confirmation and sends the note', (
    tester,
  ) async {
    when(
      () => repository.decideManualRequest(
        id: '5',
        approve: true,
        note: 'Silakan masuk',
      ),
    ).thenAnswer((_) async => const Right(null));
    await pump(tester, manualRequest());

    expect(find.text('Wajah tidak dikenali'), findsOneWidget);
    await tester.enterText(find.byType(AppTextField), 'Silakan masuk');
    await tester.tap(find.text('Setujui'));
    await tester.pumpAndSettle();

    expect(find.text('Setujui absen manual?'), findsOneWidget);
    verifyNever(
      () => repository.decideManualRequest(
        id: any(named: 'id'),
        approve: any(named: 'approve'),
        note: any(named: 'note'),
      ),
    );

    await tester.tap(inDialog('Setujui'));
    await tester.pumpAndSettle();

    verify(
      () => repository.decideManualRequest(
        id: '5',
        approve: true,
        note: 'Silakan masuk',
      ),
    ).called(1);
  });

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    await pump(tester, manualRequest());

    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    expect(find.text('Tolak absen manual?'), findsOneWidget);
    await tester.tap(inDialog('Batal'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.decideManualRequest(
        id: any(named: 'id'),
        approve: any(named: 'approve'),
        note: any(named: 'note'),
      ),
    );
  });

  testWidgets('a decided request shows who decided and no buttons', (
    tester,
  ) async {
    await pump(tester, manualRequest(status: ManualRequestStatus.approved));

    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
    expect(find.text('Diputuskan oleh'), findsOneWidget);
    expect(find.text('Lihat foto registrasi wajah'), findsOneWidget);
  });
}
