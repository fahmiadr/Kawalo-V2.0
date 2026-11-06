import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_keyboard_auto_scroller.dart';

void main() {
  group('AppKeyboardAutoScroller Unit & Widget Tests', () {
    late FocusNode node1;
    late FocusNode node2;
    late ScrollController scrollController;
    late AppKeyboardAutoScroller scroller;

    setUp(() {
      node1 = FocusNode();
      node2 = FocusNode();
      scrollController = ScrollController();
      scroller = AppKeyboardAutoScroller(
        scrollController: scrollController,
      )..registerNodes([node1, node2]);
    });

    tearDown(() {
      scroller.dispose();
      node1.dispose();
      node2.dispose();
      scrollController.dispose();
    });

    Widget buildTestApp({required Widget child}) {
      return M3EMaterialApp(
        data: AppTheme.m3eLight(),
        localizationsDelegates: AppTheme.localizationsDelegates,
        supportedLocales: AppTheme.supportedLocales,
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('registers nodes and triggers scroll when node gains focus',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              scroller.attachContext(context);
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 300),
                    TextField(focusNode: node1),
                    const SizedBox(height: 300),
                    TextField(focusNode: node2),
                    const SizedBox(height: 600),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0);

      // Focus node2
      node2.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Scroll position should have updated to bring node2 into position
      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('scrollToNode forces focus and initiates auto-scroll',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              scroller.attachContext(context);
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 400),
                    TextField(focusNode: node1),
                    const SizedBox(height: 500),
                    TextField(focusNode: node2),
                    const SizedBox(height: 600),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(node2.hasFocus, isFalse);
      expect(scrollController.offset, 0);

      scroller.scrollToNode(node2, immediate: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(node2.hasFocus, isTrue);
      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets(
      'handles switching focus to another field when keyboard dips and reopens',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                scroller.attachContext(context);
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 200),
                      TextField(focusNode: node1),
                      const SizedBox(height: 400),
                      TextField(focusNode: node2),
                      const SizedBox(height: 600),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Focus node1 initially
        node1.requestFocus();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        scroller.didChangeMetrics();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final offsetNode1 = scrollController.offset;

        // 2. Touch-switch to node2: node1 loses focus, node2 gains focus
        node1.unfocus();
        node2.requestFocus();
        // Simulate momentary dip during field handover
        tester.view.viewInsets = const FakeViewPadding(bottom: 50);
        scroller.didChangeMetrics();
        await tester.pump();

        // Reopen keyboard to full height
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        scroller.didChangeMetrics();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Must have scrolled to node2 accurately
        expect(scrollController.offset, greaterThan(offsetNode1));
      },
    );

    testWidgets(
      'handles incremental keyboard animation frames smoothly until settling',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                scroller.attachContext(context);
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 450),
                      TextField(focusNode: node1),
                      const SizedBox(height: 800),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        node1.requestFocus();
        // Simulate incremental IME frames (80dp, 160dp, 240dp, 320dp)
        tester.view.viewInsets = const FakeViewPadding(bottom: 80);
        scroller.didChangeMetrics();
        await tester.pump(const Duration(milliseconds: 20));

        tester.view.viewInsets = const FakeViewPadding(bottom: 160);
        scroller.didChangeMetrics();
        await tester.pump(const Duration(milliseconds: 20));

        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        scroller.didChangeMetrics();
        await tester.pump(const Duration(milliseconds: 20));

        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        scroller.didChangeMetrics();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(scrollController.offset, greaterThan(0));
      },
    );

    testWidgets(
      'preserves comfort zone without scrolling when input is already visible',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                scroller.attachContext(context);
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      TextField(focusNode: node1),
                      const SizedBox(height: 800),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        node1.requestFocus();
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        scroller.didChangeMetrics();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Since node1 was near the top (Y=30), it is completely in comfort zone
        expect(scrollController.offset, 0);
      },
    );

    testWidgets(
      'handles switching focus while keyboard remains open',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                scroller.attachContext(context);
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 200),
                      TextField(focusNode: node1),
                      const SizedBox(height: 400),
                      TextField(focusNode: node2),
                      const SizedBox(height: 600),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Focus node1 and open keyboard
        node1.requestFocus();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        scroller.didChangeMetrics();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final offset1 = scrollController.offset;

        // 2. Switch focus to node2 while keyboard STAYS OPEN
        node2.requestFocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(scrollController.offset, greaterThan(offset1));
      },
    );

    testWidgets(
      'handles tapping to switch focus while keyboard remains open',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                scroller.attachContext(context);
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      TextField(focusNode: node1),
                      const SizedBox(height: 320),
                      TextField(focusNode: node2),
                      const SizedBox(height: 600),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Focus node1 and open keyboard
        await tester.tap(find.byType(TextField).at(0));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        scroller.didChangeMetrics();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final offset1 = scrollController.offset;

        // 2. Tap to focus node2 directly via touch while keyboard is open
        await tester.tap(find.byType(TextField).at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final offset2 = scrollController.offset;
        expect(node2.hasFocus, isTrue);
        expect(offset2, greaterThan(offset1));
      },
    );

    testWidgets('dispose cancels pending timers cleanly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              scroller.attachContext(context);
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    TextField(focusNode: node1),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      node1.requestFocus();
      await tester.pump();

      // Dispose immediately while timers may be queued
      expect(() => scroller.dispose(), returnsNormally);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'AppScrollPadding with revealTargetKey expands scroll area to include '
      'target',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        final targetButtonKey = GlobalKey();

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                scroller.attachContext(context);
                return SingleChildScrollView(
                  controller: scrollController,
                  child: AppScrollPadding(
                    revealTargetKey: targetButtonKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        TextField(focusNode: node1),
                        const SizedBox(height: 200),
                        SizedBox(
                          key: targetButtonKey,
                          height: 48,
                          child: const Text('Target Button'),
                        ),
                        const SizedBox(height: 500),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(scrollController.offset, 0);

        // Open keyboard and focus node1
        tester.view.viewInsets = const FakeViewPadding(bottom: 500);
        scroller.didChangeMetrics();
        await tester.pump();
        node1.requestFocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Scroll offset should have adjusted so that targetButtonKey is
        // included
        expect(scrollController.offset, greaterThan(0));
      },
    );
  });
}
