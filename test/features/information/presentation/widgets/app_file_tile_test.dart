import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_file_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_file_tile.dart';

void main() {
  group('AppFileTile Core Widget Tests', () {
    testWidgets('renders filename, format subtitle, and AppFileIcon',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: Center(
              child: AppFileTile(fileName: 'laporan_tahunan.pdf'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFileTile), findsOneWidget);
      expect(find.text('laporan_tahunan.pdf'), findsOneWidget);
      expect(find.text('PDF'), findsWidgets);
      expect(find.byType(AppFileIcon), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is AppTooltip && w.message == 'laporan_tahunan.pdf',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders custom subtitle and trailing widget when provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: Center(
              child: AppFileTile(
                fileName: 'data_rekap.xlsx',
                subtitle: 'Spreadsheet Resmi',
                trailing: Icon(Icons.check),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('data_rekap.xlsx'), findsOneWidget);
      expect(find.text('Spreadsheet Resmi'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('resolves extensions correctly for word, excel, powerpoint',
        (tester) async {
      expect(AppFileTile.formatDescriptionOf('docx'), 'Word');
      expect(AppFileTile.formatDescriptionOf('xlsx'), 'Excel');
      expect(AppFileTile.formatDescriptionOf('pptx'), 'PowerPoint');
      expect(AppFileTile.formatDescriptionOf('csv'), 'CSV');
      expect(AppFileTile.formatDescriptionOf('txt'), 'Text');
      expect(AppFileTile.formatDescriptionOf('png'), 'Image');
      expect(AppFileTile.formatDescriptionOf('zip'), 'Archive');
      expect(AppFileTile.formatDescriptionOf('unknown'), 'UNKNOWN');
      expect(AppFileTile.formatDescriptionOf(''), 'Dokumen');
    });
  });
}
