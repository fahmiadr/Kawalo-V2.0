import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_card_skeleton.dart';

void main() {
  group('OperationalCardSkeleton Widget Tests', () {
    testWidgets('renders skeleton layout correctly with AppCard wrapper', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(body: OperationalCardSkeleton()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OperationalCardSkeleton), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('renders safely under reduced motion mode without animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: OperationalCardSkeleton()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OperationalCardSkeleton), findsOneWidget);
    });
  });
}
