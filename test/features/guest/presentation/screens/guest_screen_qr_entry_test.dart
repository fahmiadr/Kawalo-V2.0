import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_qr_scan_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';
import 'guest_qr_scan_screen_test.dart' show FakeGuestQrScanner;
import 'guest_screen_test.dart' show MockGuestCubit, createMockGuestCubit;

class _MockRepo extends Mock implements GuestRepository {}

class _RouteLog extends NavigatorObserver {
  final pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route.settings.name);
}

void main() {
  late MockGuestCubit cubit;
  late _MockRepo repo;
  late FakeGuestQrScanner scanner;
  late _RouteLog routes;

  Future<void> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: AppTheme.m3eLight(),
        navigatorObservers: [routes],
        home: GuestScreen(cubit: cubit, qrScannerFactory: () => scanner),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  setUp(() {
    cubit = createMockGuestCubit();
    repo = _MockRepo();
    scanner = FakeGuestQrScanner();
    routes = _RouteLog();
    when(() => cubit.guestRepository).thenReturn(repo);
  });

  testWidgets('the app bar has a "Scan QR" action that opens the scanner', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.bySemanticsLabel('Scan QR tamu'), findsOneWidget);
    expect(find.bySemanticsLabel('Cari data tamu'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Scan QR tamu'));
    await tester.pumpAndSettle();

    expect(routes.pushed, contains(AppRouteNames.guestQrScan));
    expect(find.byType(GuestQrScanScreen), findsOneWidget);
  });

  testWidgets('the action is hidden while searching', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Cari data tamu'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Scan QR tamu'), findsNothing);
  });

  testWidgets('the action is disabled during the initial load', (tester) async {
    when(() => cubit.state).thenReturn(const GuestLoading());
    await pumpScreen(tester, settle: false);

    await tester.tap(
      find.bySemanticsLabel('Scan QR tamu'),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GuestQrScanScreen), findsNothing);
  });

  testWidgets('a scanned guest opens the detail screen', (tester) async {
    when(
      () => repo.getGuestByIdentifier(
        any(),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => const Right(GuestFixtures.sampleWaitingGuest));
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Scan QR tamu'));
    await tester.pumpAndSettle();
    scanner.emit('QR-VER-RENI-10822');
    await tester.pumpAndSettle();

    expect(routes.pushed, contains(AppRouteNames.guestDetail));
    verify(
      () => cubit.onGuestUpdated(GuestFixtures.sampleWaitingGuest),
    ).called(1);
  });
}
