import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_detail_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

void main() {
  Widget buildTestableWidget(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: child),
    );
  }

  group('AttendanceDetailBottomSheet Widget Tests', () {
    late MockReverseGeocodeService mockReverseGeocodeService;

    setUp(() {
      mockReverseGeocodeService = MockReverseGeocodeService();
    });

    testWidgets(
      'renders map and resolved street address when coordinates are valid',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.208763,
            longitude: 106.845599,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.208763,
            longitude: 106.845599,
            address: 'Jl. M.H. Thamrin No. 1, Menteng, Jakarta Pusat',
          ),
        );

        const item = AttendanceItemEntity(
          id: '1',
          category: 'MASUK',
          diffMinutes: 5,
          userEmail: 'guard.ahmad@kawalo.id',
          userName: 'Ahmad Santoso',
          attendanceDt: '2026-09-10T07:05:00.000Z',
          attendanceType: 'Absen Masuk shift pagi',
          locationName: 'Gerbang Utama Pos 1',
          latitude: -6.208763,
          longitude: 106.845599,
          shiftName: 'Shift Pagi',
          shiftTimeWindow: '07:00 - 15:00',
          groupName: 'Cluster Edelweiss',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AttendanceDetailBottomSheet(
              item: item,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );

        // Awal render menampilkan placeholder shimmer skeleton
        expect(find.bySemanticsLabel('Memuat alamat lokasi'), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.text('Ahmad Santoso'), findsOneWidget);
        expect(find.text('guard.ahmad@kawalo.id'), findsOneWidget);
        expect(find.widgetWithText(AppTag, 'Masuk'), findsOneWidget);
        expect(
          find.widgetWithText(AppTag, 'Terlambat 5 menit'),
          findsOneWidget,
        );
        expect(find.text('Lokasi absensi'), findsOneWidget);
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
        final markerLayer = tester.widget<MarkerLayer>(
          find.byType(MarkerLayer),
        );
        expect(markerLayer.markers.length, equals(1));
        final marker = markerLayer.markers.first;
        expect(marker.width, equals(28));
        expect(marker.height, equals(28));
        expect(
          find.bySemanticsLabel('Titik lokasi absensi Ahmad Santoso'),
          findsOneWidget,
        );
        final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(tileLayer.tileBuilder, isNull);
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
        expect(find.text('Koordinat: -6.208763, 106.845599'), findsOneWidget);
        expect(
          find.text('Jl. M.H. Thamrin No. 1, Menteng, Jakarta Pusat'),
          findsOneWidget,
        );
        expect(find.text('Cluster Edelweiss'), findsOneWidget);
      },
    );

    testWidgets('adapts TileLayer with darkModeTileBuilder in dark mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(() => tester.view.reset());

      when(
        () => mockReverseGeocodeService.reverseGeocode(
          latitude: -6.208763,
          longitude: 106.845599,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => const ReverseGeocodeResult.success(
          latitude: -6.208763,
          longitude: 106.845599,
          address: 'Jl. M.H. Thamrin No. 1, Menteng, Jakarta Pusat',
        ),
      );

      const item = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 5,
        userEmail: 'guard.ahmad@kawalo.id',
        userName: 'Ahmad Santoso',
        attendanceDt: '2026-09-10T07:05:00.000Z',
        attendanceType: 'Absen Masuk shift pagi',
        locationName: 'Gerbang Utama Pos 1',
        latitude: -6.208763,
        longitude: 106.845599,
      );

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eDark(),
          home: Scaffold(
            body: AttendanceDetailBottomSheet(
              item: item,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.tileBuilder, equals(darkModeTileBuilder));
    });

    testWidgets(
      'renders fallback address text when reverse geocoding returns null',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.208763,
            longitude: 106.845599,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.noResult(
            latitude: -6.208763,
            longitude: 106.845599,
          ),
        );

        const item = AttendanceItemEntity(
          id: '1',
          category: 'MASUK',
          diffMinutes: 5,
          userEmail: 'guard.ahmad@kawalo.id',
          userName: 'Ahmad Santoso',
          attendanceDt: '2026-09-10T07:05:00.000Z',
          attendanceType: 'Absen Masuk shift pagi',
          locationName: 'Gerbang Utama Pos 1',
          latitude: -6.208763,
          longitude: 106.845599,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AttendanceDetailBottomSheet(
              item: item,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.textContaining('Detail alamat jalan tidak tersedia'),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Coba lagi retries reverse geocoding when initial fetch failed',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final retryCompleter = Completer<ReverseGeocodeResult>();
        var callCount = 0;
        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.208763,
            longitude: 106.845599,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future<ReverseGeocodeResult>.value(
              const ReverseGeocodeResult.failure(
                latitude: -6.208763,
                longitude: 106.845599,
                status: ReverseGeocodeStatus.networkError,
                errorMessage: 'Network error',
              ),
            );
          }
          return retryCompleter.future;
        });

        const item = AttendanceItemEntity(
          id: '1',
          category: 'MASUK',
          diffMinutes: 5,
          userEmail: 'guard.ahmad@kawalo.id',
          userName: 'Ahmad Santoso',
          attendanceDt: '2026-09-10T07:05:00.000Z',
          attendanceType: 'Absen Masuk shift pagi',
          locationName: 'Gerbang Utama Pos 1',
          latitude: -6.208763,
          longitude: 106.845599,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AttendanceDetailBottomSheet(
              item: item,
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

        expect(find.bySemanticsLabel('Memuat alamat lokasi'), findsOneWidget);

        retryCompleter.complete(
          const ReverseGeocodeResult.success(
            latitude: -6.208763,
            longitude: 106.845599,
            address: 'Jl. M.H. Thamrin No. 1, Menteng, Jakarta Pusat',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Jl. M.H. Thamrin No. 1, Menteng, Jakarta Pusat'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Detail alamat jalan tidak tersedia'),
          findsNothing,
        );
        verify(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.208763,
            longitude: 106.845599,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(2);
      },
    );

    testWidgets('renders fallback container when coordinates are invalid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(() => tester.view.reset());

      const item = AttendanceItemEntity(
        id: '2',
        category: 'LAINNYA',
        diffMinutes: 0,
        userEmail: 'guard.budi@kawalo.id',
        userName: 'Budi Pratama',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'REGISTER',
        locationName: 'Pos 2',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AttendanceDetailBottomSheet(
            item: item,
            reverseGeocodeService: mockReverseGeocodeService,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Koordinat tidak tercatat'), findsOneWidget);
      expect(
        find.text('Absensi ini dicatat tanpa data koordinat posisi.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppTag, 'Tepat waktu'), findsOneWidget);
      verifyNever(
        () => mockReverseGeocodeService.reverseGeocode(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });
  });
}
