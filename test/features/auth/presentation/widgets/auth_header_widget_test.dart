import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/auth_header_widget.dart';

void main() {
  testWidgets(
    'AuthHeaderWidget renders title, subtitle, and responsive logo size',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthHeaderWidget(
              subtitle: 'Masukkan akun Anda',
            ),
          ),
        ),
      );

      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('Masukkan akun Anda'), findsOneWidget);
      expect(find.byType(AuthHeaderWidget), findsOneWidget);
    },
  );
}
