import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_toolbar.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppToolbar Tests', () {
    testWidgets('renders AppToolbar with actions correctly', (tester) async {
      var itemTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          AppToolbar(
            actions: [
              AppToolbarAction(
                icon: Icons.edit,
                label: 'Edit',
                onPressed: () {
                  itemTapped = true;
                },
              ),
              AppToolbarAction(
                icon: Icons.share,
                label: 'Share',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppToolbar), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(itemTapped, isTrue);
    });

    testWidgets('renders AppToolbar.floating in Scaffold correctly', (
      tester,
    ) async {
      var bodyTapped = false;
      var actionTapped = false;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  bodyTapped = true;
                },
                child: const Text('Body Button'),
              ),
            ),
            floatingActionButton: AppToolbar.floating(
              alignment: AlignmentDirectional.bottomEnd,
              actions: [
                AppToolbarAction(
                  icon: Icons.delete_outline,
                  label: 'Hapus',
                  onPressed: () {
                    actionTapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppToolbar), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.text('Body Button'));
      await tester.pumpAndSettle();
      expect(bodyTapped, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(actionTapped, isTrue);
    });

    testWidgets('renders AppToolbar.floating with adjacent AppFab and widget', (
      tester,
    ) async {
      var sosTapped = false;
      var deleteTapped = false;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            floatingActionButton: AppToolbar.floating(
              alignment: AlignmentDirectional.bottomEnd,
              fabExpandsToolbar: false,
              floatingActionButton: AppFab(
                icon: const Icon(Icons.emergency),
                color: AppFabColor.error,
                onPressed: () {
                  sosTapped = true;
                },
              ),
              actions: [
                AppToolbarAction(
                  icon: Icons.delete_outline,
                  label: 'Hapus',
                  tooltip: 'Hapus item',
                  semanticLabel: 'Hapus item',
                  isDestructive: true,
                  onPressed: () {
                    deleteTapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppToolbar), findsOneWidget);
      expect(find.byType(AppFab), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.emergency));
      await tester.pumpAndSettle();
      expect(sosTapped, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(deleteTapped, isTrue);
    });
  });
}
