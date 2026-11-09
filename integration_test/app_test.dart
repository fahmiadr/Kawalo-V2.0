import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kawalo_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Login Flow Test: fill form and trigger login button', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify LoginScreen is rendered
    expect(find.text('Login'), findsWidgets);

    final emailFinder = find.widgetWithText(TextField, 'Email');
    final passwordFinder = find.widgetWithText(TextField, 'Password');
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');

    // Enter login input
    await tester.enterText(emailFinder, 'user@example.com');
    await tester.enterText(passwordFinder, 'password123');
    await tester.pumpAndSettle();

    // Tap Sign In button
    await tester.tap(signInButton);
    await tester.pumpAndSettle();
  });
}
