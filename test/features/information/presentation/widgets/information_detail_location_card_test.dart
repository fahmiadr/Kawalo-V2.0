import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_location_card.dart';
import 'package:mocktail/mocktail.dart';

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

void main() {
  Widget buildTestableWidget(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('InformationDetailLocationCard Widget Tests', () {
    late MockReverseGeocodeService mockReverseGeocodeService;

    setUp(() {
      mockReverseGeocodeService = MockReverseGeocodeService();
    });

    testWidgets(
      'renders location card with map when coordinates exist',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockReverseGeocodeService.reverseGeocode(
            latitude: -6.2088,
            longitude: 106.8456,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Jl. Sudirman, Jakarta',
          ),
        );

        const item = InformationItemEntity(
          id: 'info-1',
          photos: [],
          title: 'Sosialisasi Keamanan',
          eventLocation: 'Balai Warga RW 05',
          glat: -6.2088,
          glong: 106.8456,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            InformationDetailLocationCard(
              item: item,
              reverseGeocodeService: mockReverseGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Balai Warga RW 05'), findsOneWidget);
        expect(find.byType(AppStaticMap), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text('Jl. Sudirman, Jakarta'), findsOneWidget);
      },
    );

    testWidgets(
      'renders fallback container when coordinates are absent',
      (tester) async {
        const item = InformationItemEntity(
          id: 'info-2',
          photos: [],
          title: 'Pengumuman Kerja Bakti',
          eventLocation: 'Lapangan Olahraga',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            const InformationDetailLocationCard(item: item),
          ),
        );
        await tester.pump();

        expect(find.text('Lapangan Olahraga'), findsOneWidget);
        expect(find.byType(AppStaticMap), findsOneWidget);
        expect(find.byType(FlutterMap), findsNothing);
        expect(find.text('Koordinat tidak tercatat'), findsOneWidget);
        expect(
          find.text('Informasi ini dipublikasikan tanpa titik lokasi.'),
          findsOneWidget,
        );
      },
    );
  });
}
