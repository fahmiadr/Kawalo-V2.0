import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/widgets/manual_request_card.dart';

import '../fixtures.dart';

void main() {
  testWidgets('shows the requester avatar with the initial fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(body: ManualRequestCard(request: manualRequest())),
      ),
    );

    expect(find.byType(AppUserAvatar), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('Siti Rahmawati'), findsOneWidget);
  });
}
