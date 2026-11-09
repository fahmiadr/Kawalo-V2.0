import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/update_guest_model.dart';

void main() {
  group('UpdateGuestModel Tests', () {
    const tModel = UpdateGuestModel(
      guestName: 'John Doe Revisi',
      guestDestination: 'Blok A1 No. 5',
      guestType: 'TAMU',
      guestNumber: 'B 1234 XYZ',
      guestIdentity: '3201234567890001',
      guestIdentityType: 'KTP',
      guestPurpose: 'Kunjungan Kerja',
      guestAddress: 'Jl. Sudirman No. 1',
      guestToUserEmail: 'resident@example.com',
      guestPhoto: 'https://example.com/photo.jpg',
    );

    test('toJson serializes all non-null fields properly', () {
      final json = tModel.toJson();

      expect(json['guest_name'], 'John Doe Revisi');
      expect(json['guest_destination'], 'Blok A1 No. 5');
      expect(json['guest_type'], 'TAMU');
      expect(json['guest_number'], 'B 1234 XYZ');
      expect(json['guest_identity'], '3201234567890001');
      expect(json['guest_identity_type'], 'KTP');
      expect(json['guest_purpose'], 'Kunjungan Kerja');
      expect(json['guest_address'], 'Jl. Sudirman No. 1');
      expect(json['guest_to_user_email'], 'resident@example.com');
      expect(json['guest_photo'], 'https://example.com/photo.jpg');
    });

    test('toJson omits null fields', () {
      const partialModel = UpdateGuestModel(guestName: 'Only Name');
      final json = partialModel.toJson();

      expect(json, {'guest_name': 'Only Name'});
      expect(json.containsKey('guest_destination'), isFalse);
    });

    test('toJson includes null optional fields when includeNulls is true', () {
      const clearModel = UpdateGuestModel(
        guestName: 'Nama Revisi',
        guestDestination: 'Blok B',
        includeNulls: true,
      );
      final json = clearModel.toJson();

      expect(json['guest_name'], 'Nama Revisi');
      expect(json['guest_destination'], 'Blok B');
      expect(json.containsKey('guest_purpose'), isTrue);
      expect(json['guest_purpose'], isNull);
      expect(json.containsKey('guest_number'), isTrue);
      expect(json['guest_number'], isNull);
      expect(json.containsKey('guest_identity'), isTrue);
      expect(json['guest_identity'], isNull);
      expect(json.containsKey('guest_identity_type'), isTrue);
      expect(json['guest_identity_type'], isNull);
      expect(json.containsKey('guest_address'), isTrue);
      expect(json['guest_address'], isNull);
      expect(json.containsKey('guest_to_user_email'), isTrue);
      expect(json['guest_to_user_email'], isNull);
      expect(json.containsKey('guest_photo'), isTrue);
      expect(json['guest_photo'], isNull);
    });

    test('props equality works correctly', () {
      const otherModel = UpdateGuestModel(
        guestName: 'John Doe Revisi',
        guestDestination: 'Blok A1 No. 5',
        guestType: 'TAMU',
        guestNumber: 'B 1234 XYZ',
        guestIdentity: '3201234567890001',
        guestIdentityType: 'KTP',
        guestPurpose: 'Kunjungan Kerja',
        guestAddress: 'Jl. Sudirman No. 1',
        guestToUserEmail: 'resident@example.com',
        guestPhoto: 'https://example.com/photo.jpg',
      );
      expect(tModel, equals(otherModel));
    });
  });
}
