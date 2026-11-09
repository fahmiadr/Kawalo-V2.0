import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/checkout_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/create_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_request_model.dart';

void main() {
  group('CheckoutGuestModel.toJson', () {
    test('omits qr_uid when null', () {
      expect(const CheckoutGuestModel().toJson(), <String, dynamic>{});
    });

    test('includes qr_uid when set', () {
      expect(const CheckoutGuestModel(qrUid: 'QR1').toJson(), {
        'qr_uid': 'QR1',
      });
    });
  });

  group('CreateGuestModel.toJson', () {
    test('keeps only required keys when optionals are null', () {
      expect(
        const CreateGuestModel(
          guestName: 'Budi',
          guestDestination: 'A1',
          guestType: 'TAMU',
        ).toJson(),
        {'guest_name': 'Budi', 'guest_destination': 'A1', 'guest_type': 'TAMU'},
      );
    });

    test('includes every optional key when set', () {
      expect(
        const CreateGuestModel(
          guestName: 'Budi',
          guestDestination: 'A1',
          guestType: 'TAMU',
          guestPurpose: 'p',
          guestNumber: 'B 1 X',
          guestIdentity: '123',
          guestIdentityType: 'KTP',
          guestAddress: 'addr',
          guestToUserEmail: 'a@b.c',
          guestPhoto: 'url',
          guestDt: '2026-01-01T00:00:00Z',
        ).toJson(),
        {
          'guest_name': 'Budi',
          'guest_destination': 'A1',
          'guest_type': 'TAMU',
          'guest_purpose': 'p',
          'guest_number': 'B 1 X',
          'guest_identity': '123',
          'guest_identity_type': 'KTP',
          'guest_address': 'addr',
          'guest_to_user_email': 'a@b.c',
          'guest_photo': 'url',
          'guest_dt': '2026-01-01T00:00:00Z',
        },
      );
    });

    test('includes only the optional keys that are set', () {
      expect(
        const CreateGuestModel(
          guestName: 'Budi',
          guestDestination: 'A1',
          guestType: 'TAMU',
          guestNumber: 'B 1 X',
          guestDt: '2026-01-01T00:00:00Z',
        ).toJson(),
        {
          'guest_name': 'Budi',
          'guest_destination': 'A1',
          'guest_type': 'TAMU',
          'guest_number': 'B 1 X',
          'guest_dt': '2026-01-01T00:00:00Z',
        },
      );
    });
  });

  test('DeleteBatchGuestRequestModel.toJson wraps ids', () {
    expect(const DeleteBatchGuestRequestModel(ids: ['1', '2']).toJson(), {
      'ids': ['1', '2'],
    });
    expect(const DeleteBatchGuestRequestModel(ids: []).toJson(), {
      'ids': <String>[],
    });
  });
}
