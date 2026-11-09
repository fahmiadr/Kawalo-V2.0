import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:kawalo_mobile/core/security/presentation/app_security_blocked_screen.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(SecurityViolationType violation) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: AppSecurityBlockedScreen(violationType: violation),
    );
  }

  group('AppSecurityBlockedScreen Widget Tests', () {
    testWidgets('renders Root/Jailbreak violation message correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(SecurityViolationType.rootOrJailbreak),
      );

      expect(
        find.text('Perangkat tidak memenuhi standar keamanan'),
        findsOneWidget,
      );
      expect(find.textContaining('telah dimodifikasi'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is AppSvgIcon && w.assetPath == KawaloVectors.shieldOffFilled,
        ),
        findsOneWidget,
      );
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Tutup aplikasi'), findsOneWidget);
    });

    testWidgets('renders Mock GPS violation message correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(SecurityViolationType.mockLocation),
      );

      expect(find.text('Lokasi tiruan terdeteksi'), findsOneWidget);
      expect(find.textContaining('penyedia lokasi tiruan'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is AppSvgIcon &&
              w.assetPath == KawaloVectors.gpsDisconnectedFilled,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Unofficial Store violation message correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(SecurityViolationType.unofficialStore),
      );

      expect(find.text('Aplikasi tidak resmi terdeteksi'), findsOneWidget);
      expect(find.textContaining('toko aplikasi resmi'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.shieldXFilled,
        ),
        findsOneWidget,
      );
    });

    testWidgets('has accessible touch target for exit button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(SecurityViolationType.rootOrJailbreak),
      );

      final buttonFinder = find.byType(AppButton);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('triggers onExit callback when exit button is tapped', (
      tester,
    ) async {
      var exitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AppSecurityBlockedScreen(
            violationType: SecurityViolationType.rootOrJailbreak,
            onExit: () => exitCalled = true,
          ),
        ),
      );

      final buttonFinder = find.widgetWithText(AppButton, 'Tutup aplikasi');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(exitCalled, isTrue);
    });
  });
}
