import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppSearchBar Pure M3E Tests', () {
    testWidgets(
      'renders pure M3E search bar with hintText and no leading/trailing by default',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const SizedBox(
              width: 300,
              child: AppSearchBar(
                hintText: 'Cari tamu...',
                constraints: BoxConstraints(minHeight: 40, maxHeight: 40),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cari tamu...'), findsOneWidget);
        expect(find.byType(M3ESearchBar), findsOneWidget);
      },
    );

    testWidgets('supports explicit custom leading and trailing widgets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppSearchBar(
            leading: AppSvgIcon(KawaloVectors.search01),
            trailing: [Text('Filter')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSvgIcon), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('handles text input with trim and toLowerCase sanitization', (
      WidgetTester tester,
    ) async {
      var submittedQuery = '';

      await tester.pumpWidget(
        buildTestApp(
          AppSearchBar(
            onChanged: (val) {
              submittedQuery = val;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppSearchBar), 'Ahmad');
      await tester.pumpAndSettle();

      expect(submittedQuery, equals('ahmad'));
    });

    testWidgets('disallows leading whitespace in real-time', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      var changedValue = '';

      await tester.pumpWidget(
        buildTestApp(
          AppSearchBar(
            controller: controller,
            onChanged: (val) => changedValue = val,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppSearchBar), '   Budi');
      await tester.pumpAndSettle();

      expect(controller.text, equals('Budi'));
      expect(changedValue, equals('budi'));
    });

    testWidgets('collapses consecutive multi-whitespace in real-time', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestApp(AppSearchBar(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppSearchBar), 'Budi   Santoso');
      await tester.pumpAndSettle();

      expect(controller.text, equals('Budi Santoso'));
    });

    testWidgets(
      'onSubmitted trims trailing whitespace and converts to lowercase',
      (WidgetTester tester) async {
        final controller = TextEditingController();
        var submittedValue = '';

        await tester.pumpWidget(
          buildTestApp(
            AppSearchBar(
              controller: controller,
              onSubmitted: (val) => submittedValue = val,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'Patroli   ');
        await tester.pumpAndSettle();

        // Submit via IME action
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(controller.text, equals('patroli'));
        expect(submittedValue, equals('patroli'));
      },
    );

    testWidgets('trims trailing whitespace on focus loss', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        buildTestApp(
          AppSearchBar(controller: controller, focusNode: focusNode),
        ),
      );
      await tester.pumpAndSettle();

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(find.byType(AppSearchBar), 'Admin ');
      expect(controller.text, equals('Admin '));

      // Unfocus
      focusNode.unfocus();
      await tester.pumpAndSettle();

      expect(controller.text, equals('Admin'));
      focusNode.dispose();
      controller.dispose();
    });

    testWidgets(
      'onSearch debounces typed input and dispatches after duration',
      (WidgetTester tester) async {
        String? searchedQuery;
        var dispatchCount = 0;

        await tester.pumpWidget(
          buildTestApp(
            AppSearchBar(
              debounceDuration: const Duration(milliseconds: 200),
              onSearch: (val) {
                searchedQuery = val;
                dispatchCount++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'Satpam');
        // Before debounce duration: onSearch not yet dispatched
        await tester.pump(const Duration(milliseconds: 100));
        expect(searchedQuery, isNull);
        expect(dispatchCount, 0);

        // After debounce completes: onSearch dispatched once
        await tester.pump(const Duration(milliseconds: 150));
        expect(searchedQuery, 'satpam');
        expect(dispatchCount, 1);
      },
    );

    testWidgets(
      'onSearch dispatches immediately on submit and cancels debounce',
      (WidgetTester tester) async {
        String? searchedQuery;
        var dispatchCount = 0;

        await tester.pumpWidget(
          buildTestApp(
            AppSearchBar(
              onSearch: (val) {
                searchedQuery = val;
                dispatchCount++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'Kompleks');
        // Submit via IME action immediately
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(searchedQuery, 'kompleks');
        expect(dispatchCount, 1);

        // Advance clock past debounce time: no duplicate dispatch
        await tester.pump(const Duration(milliseconds: 400));
        expect(dispatchCount, 1);
      },
    );

    testWidgets('onSearch deduplicates consecutive identical queries', (
      WidgetTester tester,
    ) async {
      var dispatchCount = 0;

      await tester.pumpWidget(
        buildTestApp(
          AppSearchBar(
            debounceDuration: const Duration(milliseconds: 100),
            onSearch: (_) {
              dispatchCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppSearchBar), 'test');
      await tester.pump(const Duration(milliseconds: 150));
      expect(dispatchCount, 1);

      // Enter same query again and submit
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(dispatchCount, 1);
    });

    testWidgets(
      'collapses multiple consecutive internal spaces and trailing spaces '
      'in onSearch',
      (WidgetTester tester) async {
        String? searchedQuery;
        var dispatchCount = 0;

        await tester.pumpWidget(
          buildTestApp(
            AppSearchBar(
              debounceDuration: const Duration(milliseconds: 100),
              onSearch: (val) {
                searchedQuery = val;
                dispatchCount++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter text with multiple spaces in the middle and trailing spaces
        await tester.enterText(
          find.byType(AppSearchBar),
          'Bambang    Sudarsono   ',
        );
        await tester.pump(const Duration(milliseconds: 150));

        // Multiple spaces collapsed into a single space, trailing trimmed
        expect(searchedQuery, equals('bambang sudarsono'));
        expect(dispatchCount, equals(1));

        // Adding more trailing spaces does NOT trigger another dispatch
        await tester.enterText(
          find.byType(AppSearchBar),
          'Bambang    Sudarsono     ',
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(dispatchCount, equals(1));
      },
    );
  });
}
