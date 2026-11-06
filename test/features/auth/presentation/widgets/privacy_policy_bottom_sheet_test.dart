import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/privacy_policy_bottom_sheet.dart';

void main() {
  testWidgets(
    'showPrivacyPolicyBottomSheet renders modal with title and sections',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showPrivacyPolicyBottomSheet(context),
                  child: const Text('Show Privacy Policy'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan privasi'), findsOneWidget);
      expect(find.text('1. Pengumpulan data'), findsOneWidget);
      expect(find.text('Saya mengerti'), findsOneWidget);

      await tester.ensureVisible(find.text('Saya mengerti'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan privasi'), findsNothing);
    },
  );
}
