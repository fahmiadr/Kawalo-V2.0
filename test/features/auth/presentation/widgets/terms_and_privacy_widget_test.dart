import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/terms_and_privacy_widget.dart';

void main() {
  testWidgets(
    'TermsAndPrivacyWidget renders consent text and triggers link callbacks',
    (WidgetTester tester) async {
      var privacyTapped = false;
      var termsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TermsAndPrivacyWidget(
              onPrivacyTap: () => privacyTapped = true,
              onTermsTap: () => termsTapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(TermsAndPrivacyWidget), findsOneWidget);
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Ketentuan Layanan'), findsOneWidget);
      expect(find.byType(AppTappable), findsNWidgets(2));

      await tester.tap(find.text('Kebijakan Privasi'));
      await tester.pumpAndSettle();
      expect(privacyTapped, isTrue);

      await tester.tap(find.text('Ketentuan Layanan'));
      await tester.pumpAndSettle();
      expect(termsTapped, isTrue);
    },
  );
}
