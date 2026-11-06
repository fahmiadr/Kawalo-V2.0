import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_time_picker.dart';

void main() {
  Widget buildTestApp({required WidgetBuilder onBuild}) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: Builder(builder: onBuild),
      ),
    );
  }

  group('AppTimePicker Tests', () {
    testWidgets('showAppTimePicker opens M3E TimePickerDialog and picks time',
        (tester) async {
      AppTime? selectedTime;

      await tester.pumpWidget(
        buildTestApp(
          onBuild: (context) => ElevatedButton(
            onPressed: () async {
              selectedTime = await showAppTimePicker(
                context: context,
                initialTime: const AppTime(hour: 10, minute: 30),
              );
            },
            child: const Text('Pick Time'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open time picker dialog
      await tester.tap(find.text('Pick Time'));
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.byType(AppTimePickerDialog), findsOneWidget);

      // Confirm button is present (e.g. OK)
      final okButton = find.text('OK');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      expect(selectedTime, equals(const AppTime(hour: 10, minute: 30)));
    });
  });
}
