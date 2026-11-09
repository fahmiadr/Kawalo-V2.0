import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_file_icon.dart';

void main() {
  group('AppFileIcon Core Widget Tests', () {
    testWidgets('renders badge with correct label and semantics for PDF', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: Center(child: AppFileIcon(extension: 'pdf')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFileIcon), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == 'Ikon format berkas PDF',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders badge with uppercase label for standard formats', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: Column(
              children: [
                AppFileIcon(extension: 'docx'),
                AppFileIcon(extension: 'xlsx'),
                AppFileIcon(extension: 'csv'),
                AppFileIcon(extension: 'txt'),
                AppFileIcon(extension: 'zip'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DOCX'), findsOneWidget);
      expect(find.text('XLSX'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('TXT'), findsOneWidget);
      expect(find.text('ZIP'), findsOneWidget);
    });

    testWidgets('renders fallback FILE label when extension is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: Center(child: AppFileIcon(extension: '')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FILE'), findsOneWidget);
    });
  });
}
