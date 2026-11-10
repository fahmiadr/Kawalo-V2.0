import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_qr_payload.dart';

void main() {
  group('GuestQrPayload.tryParse', () {
    test('accepts a UUID and trims surrounding whitespace', () {
      expect(
        GuestQrPayload.tryParse('  3f2b8c1e-9d4a-4e0b-8a57-1c2d3e4f5a6b\n'),
        '3f2b8c1e-9d4a-4e0b-8a57-1c2d3e4f5a6b',
      );
    });

    test('accepts prefixed tokens with underscore and dash', () {
      expect(GuestQrPayload.tryParse('QR-VER_2706-SBX'), 'QR-VER_2706-SBX');
    });

    test('accepts exactly 64 characters and rejects 65', () {
      expect(GuestQrPayload.tryParse('a' * 64), 'a' * 64);
      expect(GuestQrPayload.tryParse('a' * 65), isNull);
    });

    test('rejects null, empty and blank text', () {
      expect(GuestQrPayload.tryParse(null), isNull);
      expect(GuestQrPayload.tryParse(''), isNull);
      expect(GuestQrPayload.tryParse('   '), isNull);
    });

    test('rejects text the API path would not accept', () {
      expect(GuestQrPayload.tryParse('https://kawalo.id/g/abc'), isNull);
      expect(GuestQrPayload.tryParse('{"qr_uid":"abc"}'), isNull);
      expect(GuestQrPayload.tryParse('abc def'), isNull);
      expect(GuestQrPayload.tryParse('../1'), isNull);
    });

    test('rejects digits-only text that the API would read as a row id', () {
      expect(GuestQrPayload.tryParse('1234'), isNull);
      expect(GuestQrPayload.tryParse('8991234567890'), isNull);
      expect(GuestQrPayload.tryParse('12a4'), '12a4');
    });
  });
}
