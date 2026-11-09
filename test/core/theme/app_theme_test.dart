import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

void main() {
  group('AppTheme Configuration & Resolution Tests', () {
    test(
      'AppTheme constants and theme generators produce correct brightness',
      () {
        final lightTheme = AppTheme.m3eLight();
        final darkTheme = AppTheme.m3eDark();

        expect(lightTheme.colorScheme.brightness, Brightness.light);
        expect(darkTheme.colorScheme.brightness, Brightness.dark);

        final lightColorScheme = AppTheme.lightColorScheme();
        final darkColorScheme = AppTheme.darkColorScheme();

        expect(lightColorScheme.brightness, Brightness.light);
        expect(darkColorScheme.brightness, Brightness.dark);

        final lightThemeData = AppTheme.lightThemeData();
        final darkThemeData = AppTheme.darkThemeData();

        expect(lightThemeData.brightness, Brightness.light);
        expect(darkThemeData.brightness, Brightness.dark);
      },
    );

    testWidgets(
      'M3EMaterialApp with autoTheming adapts to dark platform brightness',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark),
            child: M3EMaterialApp(
              data: AppTheme.m3eLight(),
              autoTheming: true,
              home: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Scaffold(body: SizedBox());
                },
              ),
            ),
          ),
        );

        final theme = AppTheme.of(capturedContext);
        expect(theme.colorScheme.brightness, Brightness.dark);
      },
    );

    testWidgets(
      'M3EMaterialApp with autoTheming adapts to light platform brightness',
      (tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: M3EMaterialApp(
              data: AppTheme.m3eLight(),
              autoTheming: true,
              home: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Scaffold(body: SizedBox());
                },
              ),
            ),
          ),
        );

        final theme = AppTheme.of(capturedContext);
        expect(theme.colorScheme.brightness, Brightness.light);
      },
    );

    testWidgets(
      'M3EMaterialApp supports id and id_ID locales with AppTheme delegates',
      (tester) async {
        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            localizationsDelegates: AppTheme.localizationsDelegates,
            supportedLocales: AppTheme.supportedLocales,
            locale: const Locale('id', 'ID'),
            home: const Scaffold(body: Center(child: Text('Kawalo ID'))),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Kawalo ID'), findsOneWidget);
      },
    );
  });
}
