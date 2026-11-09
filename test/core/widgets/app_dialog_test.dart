import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';

void main() {
  group('AppDialog Tests', () {
    testWidgets('AppDialog renders content correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppDialog(
              title: 'Judul Dialog',
              content: Text('Konten Dialog'),
              actions: [Text('Aksi')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Judul Dialog'), findsOneWidget);
      expect(find.text('Konten Dialog'), findsOneWidget);
      expect(find.text('Aksi'), findsOneWidget);
    });

    testWidgets('AppDialog.showFullScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppDialog.showFullScreen<void>(
                    context,
                    title: 'Detail Tamu',
                    body: const Text('Body Detail'),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Tamu'), findsOneWidget);
      expect(find.text('Body Detail'), findsOneWidget);
    });

    testWidgets(
      'AppDialog.showFullScreen uses FadeTransition when reduced motion is '
      'enabled',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      AppDialog.showFullScreen<void>(
                        context,
                        title: 'Dialog Reduced Motion',
                        body: const Text('Isi Dialog'),
                      );
                    },
                    child: const Text('Buka'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Buka'));
        await tester.pump();

        expect(find.byType(FadeTransition), findsWidgets);
        await tester.pumpAndSettle();

        expect(find.text('Dialog Reduced Motion'), findsOneWidget);
      },
    );

    testWidgets(
      'AppDialog.showFullScreen is a PageRoute that enables Hero transitions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppDialog.showFullScreen<void>(
                      context,
                      title: 'Dialog Hero',
                      body: Builder(
                        builder: (dialogCtx) => ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).push<void>(
                              PageRouteBuilder<void>(
                                pageBuilder: (_, _, _) => const Scaffold(
                                  body: Hero(
                                    tag: 'test_hero',
                                    child: Text('Viewer Hero'),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Hero(
                            tag: 'test_hero',
                            child: Text('Thumbnail Hero'),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Thumbnail Hero'), findsOneWidget);

        // Tap hero child inside dialog to push destination PageRoute
        await tester.tap(find.text('Thumbnail Hero'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        await tester.pumpAndSettle();
        expect(find.text('Viewer Hero'), findsOneWidget);

        // Pop back to fullscreen dialog
        Navigator.of(tester.element(find.text('Viewer Hero'))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Thumbnail Hero'), findsOneWidget);
      },
    );
  });
}
