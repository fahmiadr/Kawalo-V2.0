import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(body: child),
    );
  }

  group('AppEmptyState Widget Tests', () {
    testWidgets('renders default AppEmptyState with icon, title, and '
        'description', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppEmptyState(
            icon: Icon(Icons.folder_open),
            title: 'Belum ada berkas',
            description: 'Tidak ada berkas yang tersimpan saat ini.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('Belum ada berkas'), findsOneWidget);
      expect(
        find.text('Tidak ada berkas yang tersimpan saat ini.'),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollable.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    testWidgets(
      'renders action button via actionLabel in default AppEmptyState',
      (tester) async {
        var actionTriggered = false;

        await tester.pumpWidget(
          buildTestWidget(
            AppEmptyState(
              icon: const Icon(Icons.inbox),
              title: 'Kotak masuk kosong',
              description: 'Pesan Anda akan muncul di sini.',
              actionLabel: 'Perbarui',
              onActionPressed: () => actionTriggered = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Perbarui'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
        await tester.tap(find.text('Perbarui'));
        await tester.pumpAndSettle();

        expect(actionTriggered, isTrue);
      },
    );

    testWidgets('renders custom action widget in default AppEmptyState', (
      tester,
    ) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppEmptyState(
            icon: const Icon(Icons.inbox),
            title: 'Kotak masuk kosong',
            description: 'Pesan Anda akan muncul di sini.',
            action: ElevatedButton(
              onPressed: () => actionTriggered = true,
              child: const Text('Perbarui'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perbarui'), findsOneWidget);
      await tester.tap(find.text('Perbarui'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });

    testWidgets(
      'renders AppEmptyState.search with search icon and actionLabel',
      (tester) async {
        var resetTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            AppEmptyState.search(
              title: 'Tidak ada hasil ditemukan',
              description: 'Coba ubah kata kunci pencarian Anda.',
              actionLabel: 'Reset Filter & Pencarian',
              onActionPressed: () => resetTapped = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppSvgIcon), findsOneWidget);
        expect(find.text('Tidak ada hasil ditemukan'), findsOneWidget);
        expect(
          find.text('Coba ubah kata kunci pencarian Anda.'),
          findsOneWidget,
        );
        expect(find.text('Reset Filter & Pencarian'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);

        await tester.tap(find.text('Reset Filter & Pencarian'));
        await tester.pumpAndSettle();

        expect(resetTapped, isTrue);
      },
    );

    testWidgets('renders AppEmptyState.search with custom action widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppEmptyState.search(
            title: 'Pencarian kosong',
            description: 'Tidak ada kecocokan.',
            action: Text('Aksi Kustom'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aksi Kustom'), findsOneWidget);
    });

    testWidgets('renders AppEmptyState.error with alert icon and retryLabel', (
      tester,
    ) async {
      var retryTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppEmptyState.error(
            title: 'Gagal memuat data',
            description: 'Koneksi internet terputus.',
            retryLabel: 'Coba lagi',
            onRetry: () => retryTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSvgIcon), findsOneWidget);
      expect(find.text('Gagal memuat data'), findsOneWidget);
      expect(find.text('Koneksi internet terputus.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(retryTapped, isTrue);
    });
  });
}
