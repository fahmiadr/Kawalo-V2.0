import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:mocktail/mocktail.dart';

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

class MockAppLauncherService extends Mock implements AppLauncherService {}

void main() {
  Widget buildTestableWidget(
    Widget child, {
    bool isDark = false,
  }) {
    return M3EMaterialApp(
      data: isDark ? AppTheme.m3eDark() : AppTheme.m3eLight(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('AppStaticMap Widget Tests', () {
    late MockReverseGeocodeService mockReverseGeocodeService;

    setUp(() {
      mockReverseGeocodeService = MockReverseGeocodeService();
    });

    testWidgets(
      'renders fallback card when coordinates are null',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: null,
              longitude: null,
              noGpsTitle: 'Tidak ada koordinat',
              noGpsDescription: 'Posisi tidak dapat ditentukan.',
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FlutterMap), findsNothing);
        expect(find.text('Tidak ada koordinat'), findsOneWidget);
        expect(find.text('Posisi tidak dapat ditentukan.'), findsOneWidget);
      },
    );

    testWidgets(
      'renders map, marker, attribution, coordinates and address when valid',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2,
            longitude: 106.8,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2,
            longitude: 106.8,
            address: 'Jl. Sudirman No. 10, Jakarta',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              locationSemanticLabel: 'Lokasi Kantor Utama',
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );

        // Awalnya menampilkan shimmer skeleton
        expect(
          find.bySemanticsLabel('Memuat alamat lokasi'),
          findsOneWidget,
        );

        await tester.pumpAndSettle();

        // Peta non-interaktif
        final mapFinder = find.byType(FlutterMap);
        expect(mapFinder, findsOneWidget);
        final flutterMap = tester.widget<FlutterMap>(mapFinder);
        expect(
          flutterMap.options.interactionOptions.flags,
          equals(InteractiveFlag.none),
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.child is FlutterMap,
          ),
          findsOneWidget,
        );

        // Marker & Semantics
        final markerLayer =
            tester.widget<MarkerLayer>(find.byType(MarkerLayer));
        expect(markerLayer.markers.length, equals(1));
        final marker = markerLayer.markers.first;
        expect(marker.width, equals(28));
        expect(marker.height, equals(28));
        expect(find.bySemanticsLabel('Lokasi Kantor Utama'), findsOneWidget);

        // Atribusi & Koordinat
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
        expect(find.text('Koordinat: -6.2, 106.8'), findsOneWidget);

        // Alamat hasil geocoding
        expect(find.text('Jl. Sudirman No. 10, Jakarta'), findsOneWidget);
      },
    );

    testWidgets(
      'adapts TileLayer with darkModeTileBuilder in dark mode',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2,
            longitude: 106.8,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2,
            longitude: 106.8,
            address: 'Alamat Uji Coba',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
            isDark: true,
          ),
        );
        await tester.pumpAndSettle();

        final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(tileLayer.tileBuilder, equals(darkModeTileBuilder));
      },
    );

    testWidgets(
      'hides coordinates and address when toggled off',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              showCoordinates: false,
              showAddress: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.textContaining('Koordinat:'), findsNothing);
        expect(
          find.bySemanticsLabel('Memuat alamat lokasi'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'handles retry on address resolution failure',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final retryCompleter = Completer<ReverseGeocodeResult>();
        var callCount = 0;
        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2,
            longitude: 106.8,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future<ReverseGeocodeResult>.value(
              const ReverseGeocodeResult.failure(
                latitude: -6.2,
                longitude: 106.8,
                status: ReverseGeocodeStatus.networkError,
                errorMessage: 'Network error',
              ),
            );
          }
          return retryCompleter.future;
        });

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Detail alamat jalan tidak tersedia'),
          findsOneWidget,
        );
        final retryFinder = find.text('Coba lagi');
        expect(retryFinder, findsOneWidget);

        await tester.tap(retryFinder);
        await tester.pump();

        expect(
          find.bySemanticsLabel('Memuat alamat lokasi'),
          findsOneWidget,
        );

        retryCompleter.complete(
          const ReverseGeocodeResult.success(
            latitude: -6.2,
            longitude: 106.8,
            address: 'Jl. Gatot Subroto No. 45',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jl. Gatot Subroto No. 45'), findsOneWidget);
        expect(
          find.textContaining('Detail alamat jalan tidak tersedia'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders pre-resolved address without invoking ReverseGeocodeService',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Pra-resolusi No. 99',
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jl. Pra-resolusi No. 99'), findsOneWidget);
        expect(find.bySemanticsLabel('Memuat alamat lokasi'), findsNothing);
        verifyZeroInteractions(mockReverseGeocodeService);
      },
    );

    testWidgets(
      'invokes onAddressResolved callback when reverse geocoding completes',
      (tester) async {
        String? resolved;
        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2,
            longitude: 106.8,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2,
            longitude: 106.8,
            address: 'Jl. Kebon Sirih No. 1',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              reverseGeocodeService: mockReverseGeocodeService,
              onAddressResolved: (val) => resolved = val,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(resolved, equals('Jl. Kebon Sirih No. 1'));
      },
    );

    testWidgets(
      'treats NaN coordinates as fallback',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: double.nan,
              longitude: 106.8,
              noGpsTitle: 'Koordinat Tidak Valid',
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FlutterMap), findsNothing);
        expect(find.text('Koordinat Tidak Valid'), findsOneWidget);
      },
    );

    testWidgets(
      'supports custom fallbackBuilder when coordinates are absent',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: null,
              longitude: null,
              fallbackBuilder: (context) => const Text('Custom Fallback UI'),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Custom Fallback UI'), findsOneWidget);
      },
    );

    testWidgets(
      'renders open external map button by default when valid',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Sudirman No. 1',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Buka di Maps'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Buka lokasi -6.2, 106.8 di aplikasi peta eksternal',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides open external map button when showOpenExternalButton is false',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Sudirman No. 1',
              showOpenExternalButton: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Buka di Maps'), findsNothing);
      },
    );

    testWidgets(
      'tapping open external map button invokes AppLauncherService',
      (tester) async {
        final mockLauncher = MockAppLauncherService();
        when(
          () => mockLauncher.openMap(
            latitude: -6.2,
            longitude: 106.8,
            title: any(named: 'title'),
          ),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Sudirman No. 1',
              locationSemanticLabel: 'Lokasi Pos 1',
              launcherService: mockLauncher,
            ),
          ),
        );
        await tester.pump();

        final buttonFinder = find.text('Buka di Maps');
        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        await tester.pump();

        verify(
          () => mockLauncher.openMap(
            latitude: -6.2,
            longitude: 106.8,
            title: 'Lokasi Pos 1',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'invokes onOpenExternalMap callback when provided instead of service',
      (tester) async {
        final mockLauncher = MockAppLauncherService();
        var callbackCalled = false;

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Sudirman No. 1',
              launcherService: mockLauncher,
              onOpenExternalMap: () => callbackCalled = true,
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Buka di Maps'));
        await tester.pump();

        expect(callbackCalled, isTrue);
        verifyZeroInteractions(mockLauncher);
      },
    );

    testWidgets(
      'shows AppSnackbar when openMap returns false',
      (tester) async {
        final mockLauncher = MockAppLauncherService();
        when(
          () => mockLauncher.openMap(
            latitude: -6.2,
            longitude: 106.8,
            title: any(named: 'title'),
          ),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Sudirman No. 1',
              launcherService: mockLauncher,
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Buka di Maps'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Tidak dapat membuka aplikasi peta di perangkat ini.'),
          findsOneWidget,
        );

        AppSnackbar.hideCurrent();
        await tester.pump();
      },
    );

    testWidgets(
      'renders dot marker when markerStyle is dot',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
              markerStyle: AppStaticMapMarkerStyle.dot,
            ),
          ),
        );
        await tester.pump();

        final markerLayer =
            tester.widget<MarkerLayer>(find.byType(MarkerLayer));
        expect(markerLayer.markers.length, equals(1));
        final marker = markerLayer.markers.first;
        expect(marker.width, equals(14));
        expect(marker.height, equals(14));
      },
    );

    testWidgets(
      'supports custom markerSize',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
              markerStyle: AppStaticMapMarkerStyle.dot,
              markerSize: 20,
            ),
          ),
        );
        await tester.pump();

        final markerLayer =
            tester.widget<MarkerLayer>(find.byType(MarkerLayer));
        expect(markerLayer.markers.length, equals(1));
        final marker = markerLayer.markers.first;
        expect(marker.width, equals(20));
        expect(marker.height, equals(20));
      },
    );

    testWidgets(
      'renders custom markerWidget when provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
              markerWidget: KeyedSubtree(
                key: Key('custom_marker_key'),
                child: SizedBox(width: 32, height: 32),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('custom_marker_key')), findsOneWidget);
      },
    );

    testWidgets(
      'renders custom markerBuilder when provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
              markerBuilder: (context, lat, lng) => KeyedSubtree(
                key: Key('builder_marker_${lat}_$lng'),
                child: const SizedBox(width: 30, height: 30),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('builder_marker_-6.2_106.8')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders idle aura animation marker by default when showAura is true',
      (tester) async {
        AppStaticMap.debugEnableAuraAnimationInTests = true;
        addTearDown(() => AppStaticMap.debugEnableAuraAnimationInTests = false);

        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
            ),
          ),
        );
        await tester.pump();

        final markerFinder = find.byType(MarkerLayer);
        expect(markerFinder, findsOneWidget);

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(FlutterMap), findsOneWidget);
      },
    );

    testWidgets(
      'does not render aura when showAura is false',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
              showAura: false,
            ),
          ),
        );
        await tester.pump();

        final markerLayer =
            tester.widget<MarkerLayer>(find.byType(MarkerLayer));
        expect(markerLayer.markers.length, equals(1));
        final marker = markerLayer.markers.first;
        expect(marker.width, equals(28));
      },
    );

    testWidgets(
      'supports custom auraColor',
      (tester) async {
        const customAuraColor = Color(0xFFFF5722);
        await tester.pumpWidget(
          buildTestableWidget(
            const AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Uji Marker',
              auraColor: customAuraColor,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final markerFinder = find.byType(MarkerLayer);
        expect(markerFinder, findsOneWidget);
      },
    );

    testWidgets(
      'respects reduced motion by rendering static halo without animation',
      (tester) async {
        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: AppStaticMap(
                  latitude: -6.2,
                  longitude: 106.8,
                  address: 'Jl. Uji Marker',
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FlutterMap), findsOneWidget);
      },
    );

    testWidgets(
      'cancels in-flight reverse geocode request when widget is disposed',
      (tester) async {
        final geocodeCompleter = Completer<ReverseGeocodeResult>();
        AppCancellationToken? capturedToken;

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2,
            longitude: 106.8,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) {
          capturedToken =
              invocation.namedArguments[#cancelToken] as AppCancellationToken?;
          return geocodeCompleter.future;
        });

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );
        await tester.pump();

        expect(capturedToken, isNotNull);
        expect(capturedToken!.isCancelled, isFalse);

        // Unmount widget
        await tester.pumpWidget(
          buildTestableWidget(const SizedBox.shrink()),
        );

        // Verifikasi cancelToken dibatalkan saat AppStaticMap di-dispose
        expect(capturedToken!.isCancelled, isTrue);

        geocodeCompleter.complete(
          const ReverseGeocodeResult.cancelled(
            latitude: -6.2,
            longitude: 106.8,
          ),
        );
      },
    );

    testWidgets(
      'cancels in-flight reverse geocode request when pre-resolved '
      'address is provided',
      (tester) async {
        final geocodeCompleter = Completer<ReverseGeocodeResult>();
        AppCancellationToken? capturedToken;

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2,
            longitude: 106.8,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) {
          capturedToken =
              invocation.namedArguments[#cancelToken] as AppCancellationToken?;
          return geocodeCompleter.future;
        });

        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );
        await tester.pump();

        expect(capturedToken, isNotNull);
        expect(capturedToken!.isCancelled, isFalse);

        // Perbarui widget dengan menyertakan alamat eksplisit
        await tester.pumpWidget(
          buildTestableWidget(
            AppStaticMap(
              latitude: -6.2,
              longitude: 106.8,
              address: 'Jl. Merdeka No. 1, Jakarta',
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );
        await tester.pump();

        // Verifikasi cancelToken dibatalkan karena alamat eksplisit diberikan
        expect(capturedToken!.isCancelled, isTrue);

        geocodeCompleter.complete(
          const ReverseGeocodeResult.cancelled(
            latitude: -6.2,
            longitude: 106.8,
          ),
        );
      },
    );
  });
}
