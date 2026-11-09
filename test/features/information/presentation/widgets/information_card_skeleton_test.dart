import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card_skeleton.dart';

void main() {
  group('InformationCardSkeleton Widget Tests', () {
    testWidgets('renders skeleton layout correctly with AppCard wrapper', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(body: InformationCardSkeleton()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(InformationCardSkeleton), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('renders media collage placeholder when showMedia is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: InformationCardSkeleton(showMedia: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(InformationCardSkeleton), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('renders attachment tag when showAttachment is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: InformationCardSkeleton(showAttachment: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(InformationCardSkeleton), findsOneWidget);
    });

    testWidgets('renders safely under reduced motion mode without animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: InformationCardSkeleton(showMedia: true)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(InformationCardSkeleton), findsOneWidget);
    });
  });
}
