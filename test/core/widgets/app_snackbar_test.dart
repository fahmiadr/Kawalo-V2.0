import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';

void main() {
  group('AppSnackbar / M3ESnackbar Tests', () {
    tearDown(AppSnackbar.hideCurrent);

    testWidgets('renders snackbar message and action directly as widget',
        (WidgetTester tester) async {
      var actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSnackbar(
              message: 'Changes saved',
              actionLabel: 'Undo',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Changes saved'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });

    testWidgets('AppSnackbar.show displays snackbar over Overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Operasi berhasil',
                  );
                },
                child: const Text('Tampilkan'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tampilkan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Operasi berhasil'), findsOneWidget);
    });

    testWidgets('AppSnackbar.show deduplicates identical rapid calls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Pesan Duplikat',
                  );
                },
                child: const Text('Spam'),
              ),
            ),
          ),
        ),
      );

      // Tap 3 times rapidly
      await tester.tap(find.text('Spam'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Spam'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Spam'));
      await tester.pumpAndSettle();

      // Only one instance of the message should exist
      expect(find.text('Pesan Duplikat'), findsOneWidget);
    });

    testWidgets('AppSnackbar.hideCurrent dismisses active overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Pesan Sementara',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pesan Sementara'), findsOneWidget);

      AppSnackbar.hideCurrent();
      await tester.pumpAndSettle();
      expect(find.text('Pesan Sementara'), findsNothing);
    });

    testWidgets(
        'displays close button when no action is given and dismisses on tap',
        (WidgetTester tester) async {
      var customClosed = false;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Notifikasi tanpa action',
                    onClose: () => customClosed = true,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifikasi tanpa action'), findsOneWidget);
      final closeButtonFinder = find.bySemanticsLabel('Tutup notifikasi');
      expect(closeButtonFinder, findsOneWidget);

      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      expect(customClosed, isTrue);
      expect(find.text('Notifikasi tanpa action'), findsNothing);
    });

    testWidgets(
        'does not display close button when action is provided by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Notifikasi dengan action',
                    actionLabel: 'Lihat',
                    onAction: () {},
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifikasi dengan action'), findsOneWidget);
      expect(find.text('Lihat'), findsOneWidget);
      expect(find.bySemanticsLabel('Tutup notifikasi'), findsNothing);
    });

    testWidgets('respects showCloseIcon: false even when action is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Tanpa close icon',
                    showCloseIcon: false,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tanpa close icon'), findsOneWidget);
      expect(find.bySemanticsLabel('Tutup notifikasi'), findsNothing);
    });
  });
}
