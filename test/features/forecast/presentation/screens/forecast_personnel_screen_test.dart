import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/presentation/screens/forecast_personnel_screen.dart';

const _people = [
  ForecastPerson(email: 'g1@x.id', role: 'GUARD', name: 'Gani'),
  ForecastPerson(email: 'a1@x.id', role: 'ADMIN', name: 'Adi'),
  ForecastPerson(email: 'g2@x.id', role: 'GUARD', name: 'Gita'),
];

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              ForecastPersonnelScreen.route(
                people: _people,
                selected: const ['g1@x.id', 'g2@x.id'],
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists everyone with the selection count and role filters', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Gani'), findsOneWidget);
    expect(find.text('Adi'), findsOneWidget);
    expect(find.text('2 dari 3 dipilih'), findsOneWidget);
    expect(find.text('Pilih 2 Personil'), findsOneWidget);
    expect(find.text('Petugas 2'), findsOneWidget);

    await tester.tap(find.text('Admin 1'));
    await tester.pumpAndSettle();

    expect(find.text('Gani'), findsNothing);
    expect(find.text('Adi'), findsOneWidget);
  });

  testWidgets('search narrows the list by name or email', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(EditableText), 'gita');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Gita'), findsOneWidget);
    expect(find.text('Gani'), findsNothing);
  });

  testWidgets('confirm returns the picked emails in member order', (
    tester,
  ) async {
    List<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push(
              ForecastPersonnelScreen.route(
                people: _people,
                selected: const ['g2@x.id'],
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adi'));
    await tester.tap(find.text('Gani'));
    await tester.pump();
    await tester.tap(find.text('Pilih 3 Personil'));
    await tester.pumpAndSettle();

    expect(result, ['g1@x.id', 'a1@x.id', 'g2@x.id']);
  });
}
