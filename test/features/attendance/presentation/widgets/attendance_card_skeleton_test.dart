import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card_skeleton.dart';

void main() {
  group('AttendanceCardSkeleton Widget Tests', () {
    testWidgets('renders skeleton layout correctly with AppCard wrapper',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AttendanceCardSkeleton(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AttendanceCardSkeleton), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('renders safely under reduced motion mode without animation',
        (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AttendanceCardSkeleton(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AttendanceCardSkeleton), findsOneWidget);
    });
  });
}
