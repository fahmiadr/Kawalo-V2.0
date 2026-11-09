import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  Widget buildTestWidget({
    String message = 'Mode offline — Menampilkan data tersimpan',
    String onlineMessage = 'Kembali online',
    bool isOffline = true,
    bool useSafeArea = true,
    bool keepSafeAreaWhenHidden = false,
    Color? safeAreaColor,
    Duration onlineDwellDuration = const Duration(milliseconds: 2500),
    bool disableAnimations = false,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          viewPadding: viewPadding,
        ),
        child: Scaffold(
          bottomNavigationBar: AppBottomOfflineBanner(
            message: message,
            onlineMessage: onlineMessage,
            isOffline: isOffline,
            useSafeArea: useSafeArea,
            keepSafeAreaWhenHidden: keepSafeAreaWhenHidden,
            safeAreaColor: safeAreaColor,
            onlineDwellDuration: onlineDwellDuration,
          ),
        ),
      ),
    );
  }

  group('AppBottomOfflineBanner Widget Tests', () {
    testWidgets(
      'renders message without any action button or icon when offline',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsOneWidget,
        );
        expect(find.byType(AppSvgIcon), findsNothing);
        expect(find.text('Coba Lagi'), findsNothing);
      },
    );

    testWidgets(
      'renders within bottom SafeArea with top=false when useSafeArea=true',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SafeArea), findsOneWidget);
        final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
        expect(safeArea.top, isFalse);
        expect(safeArea.bottom, isTrue);
      },
    );

    testWidgets('does not render SafeArea when useSafeArea=false', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(useSafeArea: false));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBottomOfflineBanner),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
    });

    testWidgets('renders custom message correctly', (tester) async {
      const customMessage = 'Jaringan terputus — Menggunakan data lokal';
      await tester.pumpWidget(buildTestWidget(message: customMessage));
      await tester.pumpAndSettle();

      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('centers text content horizontally', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFinder = find.descendant(
        of: find.byType(AppBottomOfflineBanner),
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('renders SizedBox.shrink when initially online', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(isOffline: false));
      await tester.pumpAndSettle();

      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsNothing,
      );
      expect(find.text('Kembali online'), findsNothing);
    });

    testWidgets(
      'transitions from offline to "Kembali online", dwells, and exits',
      (tester) async {
        const dwellDuration = Duration(milliseconds: 1000);

        // 1. Awalnya dalam kondisi offline
        await tester.pumpWidget(
          buildTestWidget(onlineDwellDuration: dwellDuration),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsOneWidget,
        );

        // 2. Koneksi kembali pulih (isOffline: false)
        await tester.pumpWidget(
          buildTestWidget(isOffline: false, onlineDwellDuration: dwellDuration),
        );
        // Biarkan animasi transisi warna dan teks berjalan
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Pesan "Kembali online" muncul tanpa ikon
        expect(find.text('Kembali online'), findsOneWidget);
        expect(find.byType(AppSvgIcon), findsNothing);

        // 3. Masih tampil selama masa jeda keterbacaan (dwell duration)
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Kembali online'), findsOneWidget);

        // 4. Setelah jeda dwell selesai, animasi keluar meluncur dan kolaps
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        // Banner sekarang sepenuhnya tersembunyi
        expect(find.text('Kembali online'), findsNothing);
        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsNothing,
        );
      },
    );

    testWidgets('animates in when transitioning from online to offline', (
      tester,
    ) async {
      // 1. Mulai saat online
      await tester.pumpWidget(buildTestWidget(isOffline: false));
      await tester.pumpAndSettle();

      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsNothing,
      );

      // 2. Berubah ke offline
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsOneWidget,
      );
    });

    testWidgets('transitions immediately when reduced motion is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(disableAnimations: true));
      await tester.pump();

      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        buildTestWidget(
          isOffline: false,
          disableAnimations: true,
          onlineDwellDuration: const Duration(milliseconds: 500),
        ),
      );
      await tester.pump();

      expect(find.text('Kembali online'), findsOneWidget);

      // Lewati dwell duration
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Kembali online'), findsNothing);
    });

    testWidgets('renders safe area spacer with matching color when online and '
        'keepSafeAreaWhenHidden is true', (tester) async {
      const testInset = 34.0;
      const customColor = Color(0xFF123456);

      await tester.pumpWidget(
        buildTestWidget(
          isOffline: false,
          keepSafeAreaWhenHidden: true,
          safeAreaColor: customColor,
          viewPadding: const EdgeInsets.only(bottom: testInset),
        ),
      );
      await tester.pumpAndSettle();

      final coloredBoxFinder = find.descendant(
        of: find.byType(AppBottomOfflineBanner),
        matching: find.byType(ColoredBox),
      );
      expect(coloredBoxFinder, findsOneWidget);
      final coloredBox = tester.widget<ColoredBox>(coloredBoxFinder);
      expect(coloredBox.color, customColor);

      final size = tester.getSize(coloredBoxFinder);
      expect(size.height, testInset);
    });

    testWidgets('defaults safeAreaColor to surfaceContainerHigh when '
        'keepSafeAreaWhenHidden is true', (tester) async {
      const testInset = 48.0;

      await tester.pumpWidget(
        buildTestWidget(
          isOffline: false,
          keepSafeAreaWhenHidden: true,
          viewPadding: const EdgeInsets.only(bottom: testInset),
        ),
      );
      await tester.pumpAndSettle();

      final coloredBoxFinder = find.descendant(
        of: find.byType(AppBottomOfflineBanner),
        matching: find.byType(ColoredBox),
      );
      expect(coloredBoxFinder, findsOneWidget);
      final coloredBox = tester.widget<ColoredBox>(coloredBoxFinder);
      expect(
        coloredBox.color,
        AppTheme.m3eLight().colorScheme.surfaceContainerHigh,
      );

      final size = tester.getSize(coloredBoxFinder);
      expect(size.height, testInset);
    });
  });
}
