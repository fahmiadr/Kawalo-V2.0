import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_side_sheet.dart';

void main() {
  Widget buildTestApp({required WidgetBuilder onBuild}) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: Builder(builder: onBuild),
      ),
    );
  }

  group('AppSideSheet Tests', () {
    testWidgets('showAppSideSheet opens side sheet with title and content',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onBuild: (context) => ElevatedButton(
            onPressed: () {
              showAppSideSheet<void>(
                context: context,
                title: 'Panel Samping',
                body: const Text('Isi konten panel samping'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            },
            child: const Text('Buka Side Sheet'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open side sheet
      await tester.tap(find.text('Buka Side Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSideSheet), findsOneWidget);
      expect(find.text('Panel Samping'), findsOneWidget);
      expect(find.text('Isi konten panel samping'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Tap close action
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSideSheet), findsNothing);
    });
  });
}
