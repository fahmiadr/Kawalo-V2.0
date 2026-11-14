import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  const titles = [
    'Bicara dengan satu tombol',
    'Lapor dengan foto',
    'Absen dengan wajah',
  ];

  testWidgets('three slides: Selanjutnya advances, last shows Mulai Sekarang '
      'without Lewati', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    for (var i = 0; i < titles.length - 1; i++) {
      expect(find.text(titles[i]), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsNothing);
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();
    }

    expect(find.text(titles.last), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);
    expect(find.text('Selanjutnya'), findsNothing);
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets('does not auto-advance', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text(titles.first), findsOneWidget);
  });

  testWidgets('follows the dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const OnboardingScreen()),
    );
    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.dark);
  });

  testWidgets('renders without overflow at 200% text scaling', (tester) async {
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
    expect(tester.takeException(), isNull);
    expect(find.text(titles.first), findsOneWidget);
  });
}
