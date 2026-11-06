import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_shape_container.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppShapeContainer Tests', () {
    testWidgets('renders AppShapeContainer with cookie shape and child',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppShapeContainer.cookie4Sided(
            width: 100,
            height: 100,
            color: Colors.amber,
            child: Text('Cookie Shape'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppShapeContainer), findsOneWidget);
      expect(find.text('Cookie Shape'), findsOneWidget);
    });

    testWidgets('renders AppShapeContainer with heart and clover variants',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              AppShapeContainer.heart(
                width: 80,
                height: 80,
                color: Colors.red,
                child: Icon(Icons.favorite),
              ),
              AppShapeContainer.clover4Leaf(
                width: 80,
                height: 80,
                color: Colors.green,
                child: Icon(Icons.eco),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppShapeContainer), findsNWidgets(2));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });
  });
}
