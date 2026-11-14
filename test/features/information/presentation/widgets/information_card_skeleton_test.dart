import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card_skeleton.dart';

void main() {
  testWidgets('renders an AppCard placeholder hidden from semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: AppTheme.m3eLight(),
        home: const Scaffold(body: InformationCardSkeleton()),
      ),
    );

    expect(find.byType(AppCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExcludeSemantics),
        matching: find.byType(AppCard),
      ),
      findsOneWidget,
    );
  });
}
