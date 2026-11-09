import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_date_picker.dart';

void main() {
  Widget buildTestApp({required WidgetBuilder onBuild}) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          M3ETheme(data: AppTheme.m3eLight(), child: child!),
      home: Scaffold(body: Builder(builder: onBuild)),
    );
  }

  group('AppDatePicker Tests', () {
    testWidgets(
      'showAppDatePicker opens M3E DatePickerDialog and selects date',
      (tester) async {
        DateTime? selectedDate;

        await tester.pumpWidget(
          buildTestApp(
            onBuild: (context) => ElevatedButton(
              onPressed: () async {
                selectedDate = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 8, 15),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
              },
              child: const Text('Pick Date'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open date picker dialog
        await tester.tap(find.text('Pick Date'));
        await tester.pumpAndSettle();

        // Dialog is open
        expect(find.byType(AppDatePickerDialog), findsOneWidget);

        // Confirm button is present (e.g. OK)
        final okButton = find.text('OK');
        expect(okButton, findsOneWidget);
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        expect(selectedDate, equals(DateTime(2026, 8, 15)));
      },
    );

    testWidgets('showAppDateRangePicker opens M3E DateRangePickerDialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          onBuild: (context) => ElevatedButton(
            onPressed: () async {
              await showAppDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
            },
            child: const Text('Pick Range'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick Range'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDateRangePickerDialog), findsOneWidget);
    });
  });
}
