import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';

void main() {
  group('AppTextField / M3ETextField Tests', () {
    testWidgets('renders label and handles text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Email Label',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Email Label'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'user@test.com');
      expect(controller.text, equals('user@test.com'));
    });

    testWidgets('renders supportingText and errorText correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Password',
              supportingText: 'Minimal 8 karakter',
            ),
          ),
        ),
      );

      expect(find.text('Minimal 8 karakter'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Password',
              errorText: 'Password salah',
            ),
          ),
        ),
      );

      expect(find.text('Password salah'), findsOneWidget);
    });

    testWidgets('supports leading and trailing widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Search',
              leading: Icon(Icons.search),
              trailing: Icon(Icons.clear),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });
}
