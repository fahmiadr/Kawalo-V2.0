import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';

void main() {
  group('AppFormSection Tests', () {
    testWidgets('renders title, subtitle, and child inside AppCard',
        (tester) async {
      await tester.pumpWidget(
        M3ETheme(
          data: AppTheme.m3eLight(),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const Scaffold(
              body: AppFormSection(
                title: 'Informasi tamu',
                subtitle: 'Data pengunjung',
                child: Text('Form Section Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Informasi tamu'), findsOneWidget);
      expect(find.text('Data pengunjung'), findsOneWidget);
      expect(find.text('Form Section Child'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('renders uncontained mode without AppCard', (tester) async {
      await tester.pumpWidget(
        M3ETheme(
          data: AppTheme.m3eLight(),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const Scaffold(
              body: AppFormSection.uncontained(
                title: 'Foto dokumentasi',
                subtitle: 'Lampiran foto',
                child: Text('Uncontained Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Foto dokumentasi'), findsOneWidget);
      expect(find.text('Lampiran foto'), findsOneWidget);
      expect(find.text('Uncontained Child'), findsOneWidget);
      expect(find.byType(AppCard), findsNothing);
    });
  });
}
