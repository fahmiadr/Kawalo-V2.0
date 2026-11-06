import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';

void main() {
  group('GuestModel Tests', () {
    final tJson = {
      'id': '1',
      'guest_name': 'Bambang',
      'guest_number': 'B 2706 SBX',
      'guest_category': 'Taxi',
      'guest_destination': 'Pos 1',
      'guest_purpose': 'Jemput',
      'guest_dt': '2026-09-10T10:00:00.000Z',
      'group_uid': null,
      'group_name': null,
      'guest_identity': null,
      'guest_identity_type': null,
      'guest_to_user_name': null,
      'guest_to_user_email': null,
      'guest_creator_name': null,
      'guest_creator_email': null,
      'guest_ack_dt': null,
      'guest_out_dt': null,
      'guest_photo': null,
      'qr_uid': null,
      'guest_address': null,
      'guest_type': null,
      'guest_checkout_by_email': null,
      'guest_checkout_by_name': null,
    };

    test('fromJson creates a valid GuestModel instance without fallbacks', () {
      final model = GuestModel.fromJson(tJson);

      expect(model.id, '1');
      expect(model.guestName, 'Bambang');
      expect(model.guestNumber, 'B 2706 SBX');
      expect(model.guestCategory, 'Taxi');
      expect(model.guestPurpose, 'Jemput');
      expect(model.guestDt, '2026-09-10T10:00:00.000Z');
      expect(model.guestDestination, 'Pos 1');
    });

    test(
      'fromJson preserves null values for nullable fields without '
      'empty string fallback',
      () {
        final jsonNulls = {
          'id': '2',
          'guest_name': null,
          'guest_number': null,
          'guest_category': null,
          'guest_destination': null,
          'guest_purpose': null,
          'guest_dt': null,
        };
        final model = GuestModel.fromJson(jsonNulls);

        expect(model.id, '2');
        expect(model.guestName, isNull);
        expect(model.guestNumber, isNull);
        expect(model.guestCategory, isNull);
        expect(model.guestDestination, isNull);
        expect(model.guestPurpose, isNull);
        expect(model.guestDt, isNull);
      },
    );

    test('props equality works as expected', () {
      const model1 = GuestModel(
        id: '1',
        guestCategory: 'Tamu',
        guestPurpose: 'Meeting',
        guestDt: '2026-09-10',
      );
      const model2 = GuestModel(
        id: '1',
        guestCategory: 'Tamu',
        guestPurpose: 'Meeting',
        guestDt: '2026-09-10',
      );
      const model3 = GuestModel(
        id: '2',
        guestCategory: 'Tamu',
        guestPurpose: 'Meeting',
        guestDt: '2026-09-10',
      );

      expect(model1, equals(model2));
      expect(model1 == model3, isFalse);
    });
  });
}
