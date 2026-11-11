import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/presentation/qr_scan/guest_qr_scanner.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_qr_scan_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';

class _MockRepo extends Mock implements GuestRepository {}

class _MockLauncher extends Mock implements AppLauncherService {}

class FakeGuestQrScanner extends ChangeNotifier implements GuestQrScanner {
  final _codes = StreamController<String>.broadcast();
  @override
  GuestQrScannerFault? fault;
  bool disposed = false;
  int restarts = 0;
  int torchToggles = 0;

  @override
  GuestQrTorch torch = GuestQrTorch.off;

  void emit(String code) => _codes.add(code);

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Listenable get changes => this;

  @override
  Future<void> toggleTorch() async {
    torchToggles++;
    torch = torch == GuestQrTorch.on ? GuestQrTorch.off : GuestQrTorch.on;
    notifyListeners();
  }

  @override
  Future<void> restart() async => restarts++;

  @override
  Widget buildPreview(BuildContext context) =>
      const ColoredBox(color: Colors.black, child: SizedBox.expand());

  @override
  Future<void> dispose() async {
    disposed = true;
    await _codes.close();
    super.dispose();
  }
}

void main() {
  const uid = 'QR-VER-RENI-10822';
  late _MockRepo repo;
  late _MockLauncher launcher;
  late FakeGuestQrScanner scanner;
  GuestItemEntity? popped;
  var didPop = false;

  Future<void> pumpScreen(WidgetTester tester) async {
    popped = null;
    didPop = false;
    await tester.pumpWidget(
      M3EMaterialApp(
        data: AppTheme.m3eLight(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<GuestItemEntity?>(
                    MaterialPageRoute<GuestItemEntity?>(
                      builder: (_) => GuestQrScanScreen(
                        repository: repo,
                        scannerFactory: () => scanner,
                        launcherService: launcher,
                      ),
                    ),
                  );
                  didPop = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  void stubLookup(Either<Failure, GuestItemEntity> result) => when(
    () => repo.getGuestByIdentifier(
      any(),
      cancelToken: any(named: 'cancelToken'),
    ),
  ).thenAnswer((_) async => result);

  setUp(() {
    repo = _MockRepo();
    launcher = _MockLauncher();
    scanner = FakeGuestQrScanner();
  });

  testWidgets('shows the scanning hint and disposes the camera on exit', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Arahkan kamera ke kode QR tamu'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Tutup pemindai QR'));
    await tester.pumpAndSettle();

    expect(didPop, isTrue);
    expect(popped, isNull);
    expect(scanner.disposed, isTrue);
  });

  testWidgets('a resolved guest is returned to the caller', (tester) async {
    stubLookup(const Right(GuestFixtures.sampleWaitingGuest));
    await pumpScreen(tester);

    scanner.emit(uid);
    await tester.pumpAndSettle();

    expect(didPop, isTrue);
    expect(popped, GuestFixtures.sampleWaitingGuest);
  });

  testWidgets('shows "Tamu tidak ditemukan" and scans again on request', (
    tester,
  ) async {
    stubLookup(const Left(ServerFailure('Data tamu tidak ditemukan.', 404)));
    await pumpScreen(tester);

    scanner.emit(uid);
    await tester.pumpAndSettle();

    expect(find.text('Tamu tidak ditemukan'), findsOneWidget);
    expect(didPop, isFalse);

    await tester.tap(find.text('Pindai lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Arahkan kamera ke kode QR tamu'), findsOneWidget);
  });

  testWidgets('shows the forbidden message with a way back', (tester) async {
    stubLookup(const Left(AuthFailure('Anda tidak berhak.', 403)));
    await pumpScreen(tester);

    scanner.emit(uid);
    await tester.pumpAndSettle();

    expect(find.text('Anda tidak berhak.'), findsOneWidget);
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(didPop, isTrue);
  });

  testWidgets('an error offers a retry that resolves the guest', (
    tester,
  ) async {
    stubLookup(const Left(NoInternetFailure()));
    await pumpScreen(tester);

    scanner.emit(uid);
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat data tamu'), findsOneWidget);

    stubLookup(const Right(GuestFixtures.sampleWaitingGuest));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(popped, GuestFixtures.sampleWaitingGuest);
    verify(() => repo.getGuestByIdentifier(uid)).called(2);
  });

  testWidgets('the outlined action stays readable on the dark panel', (
    tester,
  ) async {
    stubLookup(const Left(NoInternetFailure()));
    await pumpScreen(tester);

    scanner.emit(uid);
    await tester.pumpAndSettle();

    final label = tester.element(find.text('Pindai lagi'));
    expect(DefaultTextStyle.of(label).style.color, Colors.white);
  });

  testWidgets('an unrelated QR is reported without calling the API', (
    tester,
  ) async {
    await pumpScreen(tester);

    scanner.emit('https://example.com');
    await tester.pumpAndSettle();

    expect(find.text('Kode QR tidak dikenali'), findsOneWidget);
    verifyZeroInteractions(repo);
  });

  testWidgets('the torch button toggles the torch', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Nyalakan lampu senter'));
    await tester.pumpAndSettle();

    expect(scanner.torchToggles, 1);
    expect(find.bySemanticsLabel('Matikan lampu senter'), findsOneWidget);
  });

  testWidgets('the torch button is disabled when unsupported', (tester) async {
    scanner.torch = GuestQrTorch.unavailable;
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Nyalakan lampu senter'));
    await tester.pumpAndSettle();

    expect(scanner.torchToggles, 0);
  });

  testWidgets('denied camera permission explains and offers the settings', (
    tester,
  ) async {
    when(() => launcher.openAppSettings()).thenAnswer((_) async => true);
    scanner.fault = GuestQrScannerFault.permissionDenied;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester);

    expect(find.text('Izin kamera dinonaktifkan'), findsOneWidget);

    await tester.tap(find.text('Buka pengaturan'));
    await tester.pump();
    verify(() => launcher.openAppSettings()).called(1);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(scanner.restarts, 1);
  });

  testWidgets('an unavailable camera offers a retry', (tester) async {
    scanner.fault = GuestQrScannerFault.unavailable;
    await pumpScreen(tester);

    expect(find.text('Kamera tidak tersedia'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(scanner.restarts, 1);
  });
}
