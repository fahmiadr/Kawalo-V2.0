import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card.dart';

void main() {
  Widget host(Widget child) => M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(body: child),
  );

  testWidgets('early check-out is an amber pill with the minutes', (
    tester,
  ) async {
    const item = AttendanceItemEntity(
      id: '1',
      category: 'PULANG',
      diffMinutes: 0,
      earlyLeaveMinutes: 12,
      userName: 'Budi',
    );
    await tester.pumpWidget(host(const AttendanceCard(item: item)));

    final pill = tester.widget<AppStatusPill>(
      find.widgetWithText(AppStatusPill, 'Pulang lebih cepat 12 menit'),
    );
    expect(pill.kind, AppStatusKind.bad);
  });

  testWidgets('shows "Tidak terverifikasi" only when faceVerified is false', (
    tester,
  ) async {
    const manual = AttendanceItemEntity(
      id: '1',
      category: 'MASUK',
      diffMinutes: 0,
      faceVerified: false,
    );
    await tester.pumpWidget(host(const AttendanceCard(item: manual)));
    expect(
      find.widgetWithText(AppStatusPill, 'Tidak terverifikasi'),
      findsOneWidget,
    );

    const unknown = AttendanceItemEntity(
      id: '2',
      category: 'MASUK',
      diffMinutes: 0,
    );
    await tester.pumpWidget(host(const AttendanceCard(item: unknown)));
    expect(find.text('Tidak terverifikasi'), findsNothing);
  });

  testWidgets('similarity tag shows for admin only', (tester) async {
    const item = AttendanceItemEntity(
      id: '1',
      category: 'MASUK',
      diffMinutes: 0,
      faceVerified: true,
      faceSimilarityPercent: 87,
    );
    Widget asRole(String role) => BlocProvider<UserSessionCubit>.value(
      value: UserSessionCubit(
        AuthSessionEntity(
          userId: '1',
          email: 'a@kawalo.id',
          name: 'A',
          role: role,
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        ),
      ),
      child: host(const AttendanceCard(item: item)),
    );

    await tester.pumpWidget(asRole('ADMIN'));
    expect(find.textContaining('Kemiripan 87%'), findsOneWidget);

    await tester.pumpWidget(asRole('GUARD'));
    expect(find.textContaining('Kemiripan'), findsNothing);

    await tester.pumpWidget(host(const AttendanceCard(item: item)));
    expect(find.textContaining('Kemiripan'), findsNothing);
  });
}
