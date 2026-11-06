import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/create_guest_model.dart';

void main() {
  group('CreateGuestModel Tests', () {
    const tModel = CreateGuestModel(
      guestName: 'John Doe',
      guestDestination: 'Blok A1 No. 5',
      guestType: 'TAMU',
      guestNumber: 'B 1234 XYZ',
      guestIdentity: '3201234567890001',
      guestIdentityType: 'KTP',
      guestPurpose: 'Kunjungan Keluarga',
      guestAddress: 'Jl. Sudirman No. 1',
      guestToUserEmail: 'resident@example.com',
      guestPhoto: 'https://example.com/photo.jpg',
      guestDt: '2026-09-21T10:00:00.000Z',
    );

    test('toJson serializes all fields properly', () {
      final json = tModel.toJson();

      expect(json['guest_name'], 'John Doe');
      expect(json['guest_destination'], 'Blok A1 No. 5');
      expect(json['guest_type'], 'TAMU');
      expect(json['guest_number'], 'B 1234 XYZ');
      expect(json['guest_identity'], '3201234567890001');
      expect(json['guest_identity_type'], 'KTP');
      expect(json['guest_purpose'], 'Kunjungan Keluarga');
      expect(json['guest_address'], 'Jl. Sudirman No. 1');
      expect(json['guest_to_user_email'], 'resident@example.com');
      expect(json['guest_photo'], 'https://example.com/photo.jpg');
      expect(json['guest_dt'], '2026-09-21T10:00:00.000Z');
    });
  });
}
