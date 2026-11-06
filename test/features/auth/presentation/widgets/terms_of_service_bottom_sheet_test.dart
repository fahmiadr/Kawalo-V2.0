import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/terms_of_service_bottom_sheet.dart';

void main() {
  testWidgets(
    'showTermsOfServiceBottomSheet renders modal with title and sections',
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
                  onPressed: () => showTermsOfServiceBottomSheet(context),
                  child: const Text('Show Terms'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Terms'));
      await tester.pumpAndSettle();

      expect(find.text('Ketentuan layanan'), findsOneWidget);
      expect(find.text('1. Ketentuan Umum'), findsOneWidget);
      expect(find.text('Saya mengerti'), findsOneWidget);

      await tester.ensureVisible(find.text('Saya mengerti'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Ketentuan layanan'), findsNothing);
    },
  );
}
