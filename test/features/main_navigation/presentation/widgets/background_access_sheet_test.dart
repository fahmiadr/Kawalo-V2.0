import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/background_access_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/background_access_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockBackgroundAccessService extends Mock
    implements BackgroundAccessService {}

const _askable = BackgroundAccessStatus(
  grants: {
    BackgroundAccessItem.notifications: BackgroundAccessGrant.askable,
    BackgroundAccessItem.microphone: BackgroundAccessGrant.granted,
    BackgroundAccessItem.battery: BackgroundAccessGrant.refused,
  },
);

void main() {
  setUpAll(() => registerFallbackValue(BackgroundAccessItem.notifications));

  late MockBackgroundAccessService service;

  setUp(() {
    BackgroundAccessSheet.resetForTest();
    service = MockBackgroundAccessService();
    when(() => service.request(any())).thenAnswer((_) async => true);
    when(() => service.skip()).thenAnswer((_) async {});
  });

  Future<void> pumpHost(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BackgroundAccessSheet.maybeShow(
                context,
                createCubit: () => BackgroundAccessCubit(service: service),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows each item state and requests on Izinkan', (tester) async {
    when(() => service.status()).thenAnswer((_) async => _askable);
    await pumpHost(tester);

    expect(find.text('Agar Kawalo tetap aktif'), findsOneWidget);
    expect(find.text('Belum diizinkan'), findsOneWidget);
    expect(find.text('Sudah diizinkan'), findsOneWidget);
    expect(find.text('Ditolak'), findsOneWidget);

    await tester.ensureVisible(find.text('Izinkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Izinkan'));
    await tester.pumpAndSettle();

    verify(() => service.request(BackgroundAccessItem.notifications)).called(1);
    expect(find.text('Agar Kawalo tetap aktif'), findsNothing);
  });

  testWidgets('Lewati remembers the choice and closes', (tester) async {
    when(() => service.status()).thenAnswer((_) async => _askable);
    await pumpHost(tester);

    await tester.ensureVisible(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    verify(() => service.skip()).called(1);
    verifyNever(() => service.request(any()));
    expect(find.text('Agar Kawalo tetap aktif'), findsNothing);
  });

  testWidgets('stays hidden when nothing is askable', (tester) async {
    when(() => service.status()).thenAnswer(
      (_) async => const BackgroundAccessStatus(
        grants: {
          BackgroundAccessItem.notifications: BackgroundAccessGrant.granted,
          BackgroundAccessItem.microphone: BackgroundAccessGrant.refused,
          BackgroundAccessItem.battery: BackgroundAccessGrant.granted,
        },
      ),
    );
    await pumpHost(tester);

    expect(find.text('Agar Kawalo tetap aktif'), findsNothing);
  });
}
