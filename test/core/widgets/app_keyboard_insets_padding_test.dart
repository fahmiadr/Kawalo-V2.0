import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';

void main() {
  group('AppKeyboardInsetsPadding Widget Tests', () {
    testWidgets(
      'applies full viewInsets.bottom when hasBottomNavigationBar is false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const MediaQuery(
              data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: AppKeyboardInsetsPadding(
                child: SizedBox(
                  key: Key('content'),
                  height: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paddingFinder = find.byType(Padding);
        expect(paddingFinder, findsOneWidget);

        final paddingWidget = tester.widget<Padding>(paddingFinder);
        expect(
          (paddingWidget.padding as EdgeInsets).bottom,
          equals(300.0),
        );
      },
    );

    testWidgets(
      'deducts navigation bar and safe area spacer when '
      'hasBottomNavigationBar is true and online',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const MediaQuery(
              data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: AppKeyboardInsetsPadding(
                hasBottomNavigationBar: true,
                child: SizedBox(
                  key: Key('content'),
                  height: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paddingFinder = find.byType(Padding);
        final paddingWidget = tester.widget<Padding>(paddingFinder);

        // 300 - (80 + 34) = 186.0
        expect(
          (paddingWidget.padding as EdgeInsets).bottom,
          equals(186.0),
        );
      },
    );

    testWidgets(
      'deducts navigation bar, offline banner, and safe area spacer '
      'when hasBottomNavigationBar is true and offline',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const MediaQuery(
              data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: AppKeyboardInsetsPadding(
                hasBottomNavigationBar: true,
                isOffline: true,
                child: SizedBox(
                  key: Key('content'),
                  height: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paddingFinder = find.byType(Padding);
        final paddingWidget = tester.widget<Padding>(paddingFinder);

        // 300 - (80 + 36 + 34) = 150.0
        expect(
          (paddingWidget.padding as EdgeInsets).bottom,
          equals(150.0),
        );
      },
    );

    testWidgets(
      'clamps bottom padding to 0 when keyboard height is less than '
      'navigation bar height',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const MediaQuery(
              data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 60),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: AppKeyboardInsetsPadding(
                hasBottomNavigationBar: true,
                child: SizedBox(
                  key: Key('content'),
                  height: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paddingFinder = find.byType(Padding);
        final paddingWidget = tester.widget<Padding>(paddingFinder);

        // 60 - (80 + 34) = -54 -> clamped to 0.0
        expect(
          (paddingWidget.padding as EdgeInsets).bottom,
          equals(0.0),
        );
      },
    );

    testWidgets(
      'deducts offline banner and safe area spacer when '
      'hasBottomNavigationBar is false and offline',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const MediaQuery(
              data: MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: AppKeyboardInsetsPadding(
                isOffline: true,
                child: SizedBox(
                  key: Key('content'),
                  height: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paddingFinder = find.byType(Padding);
        final paddingWidget = tester.widget<Padding>(paddingFinder);

        // 300 - (0 + 36 + 34) = 230.0
        expect(
          (paddingWidget.padding as EdgeInsets).bottom,
          equals(230.0),
        );
      },
    );

    testWidgets(
      'returns 0 bottom padding when viewInsets.bottom is 0 even if offline',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const MediaQuery(
              data: MediaQueryData(
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: AppKeyboardInsetsPadding(
                hasBottomNavigationBar: true,
                isOffline: true,
                child: SizedBox(
                  key: Key('content'),
                  height: 100,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paddingFinder = find.byType(Padding);
        final paddingWidget = tester.widget<Padding>(paddingFinder);

        expect(
          (paddingWidget.padding as EdgeInsets).bottom,
          equals(0.0),
        );
      },
    );
  });
}
