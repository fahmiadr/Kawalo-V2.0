import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_person_row.dart';

void main() {
  testWidgets('shows the shared avatar with two initials as fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: SchedulePersonRow(
            item: ManagedScheduleEntity(
              id: '1',
              date: DateTime(2026, 11, 12),
              email: 'budi@x.id',
              name: 'Budi Santoso',
              isMember: true,
              locked: false,
              avatarUrl: 'bukan-url',
            ),
            selectionMode: false,
            selected: false,
            onTap: () {},
            onLongPress: null,
          ),
        ),
      ),
    );

    expect(find.byType(AppUserAvatar), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
  });
}
