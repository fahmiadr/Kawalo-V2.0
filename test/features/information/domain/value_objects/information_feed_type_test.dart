import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/create_information_data.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/update_information_data.dart';

void main() {
  group('InformationFeedType Tests', () {
    test('has expected enum values and properties', () {
      expect(InformationFeedType.general.code, 'GENERAL');
      expect(InformationFeedType.general.label, 'Informasi Umum');

      expect(InformationFeedType.join.code, 'JOIN');
      expect(InformationFeedType.join.label, 'Personil Baru');

      expect(InformationFeedType.incident.code, 'INCIDENT');
      expect(InformationFeedType.incident.label, 'Insiden');

      expect(InformationFeedType.event.code, 'EVENT');
      expect(InformationFeedType.event.label, 'Acara');

      expect(InformationFeedType.other.code, 'OTHER');
      expect(InformationFeedType.other.label, 'Lainnya');
    });

    test('allowedCodes returns all valid backend codes', () {
      expect(InformationFeedType.allowedCodes, [
        'GENERAL',
        'JOIN',
        'INCIDENT',
        'EVENT',
        'OTHER',
      ]);
    });

    test('tryFromCode parses codes correctly', () {
      expect(
        InformationFeedType.tryFromCode('GENERAL'),
        InformationFeedType.general,
      );
      expect(InformationFeedType.tryFromCode('join'), InformationFeedType.join);
      expect(
        InformationFeedType.tryFromCode(' INCIDENT '),
        InformationFeedType.incident,
      );
      expect(
        InformationFeedType.tryFromCode('event'),
        InformationFeedType.event,
      );
      expect(
        InformationFeedType.tryFromCode('other'),
        InformationFeedType.other,
      );
      expect(InformationFeedType.tryFromCode(null), isNull);
      expect(InformationFeedType.tryFromCode('UNKNOWN'), isNull);
    });

    test(
      'CreateInformationData, UpdateInformationData, and params delegate codes',
      () {
        expect(
          CreateInformationData.allowedFeedTypes,
          InformationFeedType.allowedCodes,
        );
        expect(
          UpdateInformationData.allowedFeedTypes,
          InformationFeedType.allowedCodes,
        );
        expect(
          CreateInformationParams.allowedFeedTypes,
          InformationFeedType.allowedCodes,
        );
        expect(
          UpdateInformationParams.allowedFeedTypes,
          InformationFeedType.allowedCodes,
        );
      },
    );
  });
}
