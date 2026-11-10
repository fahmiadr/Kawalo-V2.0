import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_summary_card.dart';
import 'package:mocktail/mocktail.dart';

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

void main() {
  IncidentEntity incident({double? glat, double? glong}) => IncidentEntity(
    id: 'inc_1',
    groupId: 'grp_1',
    title: 'Pintu Gerbang Rusak',
    status: IncidentStatus.open,
    createdBy: 'guard@kawalo.id',
    createdAt: DateTime.parse('2026-11-04T10:00:00.000Z'),
    glat: glat,
    glong: glong,
  );

  Future<void> pump(WidgetTester tester, IncidentEntity incident) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final geocoder = MockReverseGeocodeService();
    when(
      () => geocoder.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const ReverseGeocodeResult.success(
        latitude: -6.2088,
        longitude: 106.8456,
        address: 'Jl. Sudirman, Jakarta',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: IncidentDetailSummaryCard(
              incident: incident,
              reverseGeocodeService: geocoder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a static map when the incident has coordinates', (
    tester,
  ) async {
    await pump(tester, incident(glat: -6.2088, glong: 106.8456));

    expect(find.byType(AppStaticMap), findsOneWidget);
    expect(find.text('Jl. Sudirman, Jakarta'), findsOneWidget);
  });

  testWidgets('shows no map without coordinates', (tester) async {
    await pump(tester, incident());

    expect(find.byType(AppStaticMap), findsNothing);
  });
}
