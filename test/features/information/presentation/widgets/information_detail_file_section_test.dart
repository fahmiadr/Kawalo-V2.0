import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_file_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_file_card.dart';

void main() {
  group('InformationDetailFileSection Widget Tests', () {
    tearDown(AppSnackbar.hideCurrent);

    const feedNoFile = InformationItemEntity(
      id: '1',
      photos: [],
      title: 'Info Tanpa Berkas',
    );

    const feedPdf = InformationItemEntity(
      id: '2',
      photos: [],
      title: 'SOP Evakuasi',
      feedFile: 'sop_evakuasi_2026.pdf',
    );

    const feedExcel = InformationItemEntity(
      id: '3',
      photos: [],
      title: 'Data Rekap Shift',
      feedFile: 'rekap_shift_oktober.xlsx',
    );

    const feedWord = InformationItemEntity(
      id: '4',
      photos: [],
      title: 'Notulen Rapat',
      feedFile: 'notulen_keamanan.docx',
    );

    testWidgets('renders nothing when no file attachment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: InformationDetailFileSection(item: feedNoFile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InformationDetailFileSection), findsOneWidget);
      expect(find.text('Berkas Lampiran'), findsNothing);
    });

    testWidgets('renders file tile, subtitle format, Buka, and Unduh for PDF',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: InformationDetailFileSection(item: feedPdf),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Berkas Lampiran'), findsOneWidget);
      expect(find.text('sop_evakuasi_2026.pdf'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is AppTooltip && w.message == 'sop_evakuasi_2026.pdf',
        ),
        findsOneWidget,
      );
      expect(find.byType(AppFileIcon), findsOneWidget);
      expect(find.text('PDF'), findsWidgets);
      expect(find.text('Buka'), findsOneWidget);
      expect(find.text('Unduh'), findsOneWidget);
      // View/inline preview is completely removed
      expect(find.text('Lihat'), findsNothing);
      expect(find.text('Tutup'), findsNothing);
    });

    testWidgets('renders Excel format subtitle for xlsx file', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: InformationDetailFileSection(item: feedExcel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('rekap_shift_oktober.xlsx'), findsOneWidget);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.text('Buka'), findsOneWidget);
      expect(find.text('Unduh'), findsOneWidget);
    });

    testWidgets('renders Word format subtitle for docx file', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: InformationDetailFileSection(item: feedWord),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('notulen_keamanan.docx'), findsOneWidget);
      expect(find.text('Word'), findsOneWidget);
      expect(find.text('Buka'), findsOneWidget);
      expect(find.text('Unduh'), findsOneWidget);
    });

    testWidgets('tapping Buka shows snackbar feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: InformationDetailFileSection(item: feedPdf),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka'));
      await tester.pump();

      expect(
        find.textContaining('Membuka "sop_evakuasi_2026.pdf"'),
        findsOneWidget,
      );

      AppSnackbar.hideCurrent();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Unduh triggers download progress and snackbar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: InformationDetailFileSection(item: feedPdf),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unduh'));
      await tester.pump();

      expect(find.text('Mengunduh...'), findsOneWidget);
    });
  });
}
