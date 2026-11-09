import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

void main() {
  group('OnboardingScreen Unit & Widget Tests', () {
    testWidgets(
      'OnboardingScreen renders progress bar, hero image, title, and action',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

        await tester.pump();
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(OnboardingProgressBar), findsOneWidget);
        expect(
          find.text('Selamat Datang di Aplikasi Kawalo 2.0 Terbaru'),
          findsOneWidget,
        );
        expect(find.text('Mulai sekarang'), findsOneWidget);
      },
    );

    testWidgets(
      'OnboardingScreen enforces light mode theme even when parent is dark '
      'mode',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: ThemeData.dark(), home: const OnboardingScreen()),
        );

        await tester.pump();
        final scaffoldFinder = find.byType(Scaffold);
        expect(scaffoldFinder, findsOneWidget);

        final scaffold = tester.widget<Scaffold>(scaffoldFinder);
        final theme = Theme.of(tester.element(scaffoldFinder));
        expect(theme.brightness, equals(Brightness.light));
        expect(scaffold.backgroundColor, equals(theme.colorScheme.surface));
      },
    );

    testWidgets(
      'OnboardingScreen respects reduced motion setting without auto-advance',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                accessibleNavigation: true,
                disableAnimations: true,
              ),
              child: OnboardingScreen(),
            ),
          ),
        );

        await tester.pump();
        expect(
          find.text('Selamat Datang di Aplikasi Kawalo 2.0 Terbaru'),
          findsOneWidget,
        );

        // Advance past 4 seconds
        await tester.pump(const Duration(seconds: 5));

        // In reduced motion, it remains on step 1 (does not auto advance)
        expect(
          find.text('Selamat Datang di Aplikasi Kawalo 2.0 Terbaru'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OnboardingScreen renders without overflow at 200% text scaling',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: OnboardingScreen(),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(
          find.text('Selamat Datang di Aplikasi Kawalo 2.0 Terbaru'),
          findsOneWidget,
        );
      },
    );
  });
}
