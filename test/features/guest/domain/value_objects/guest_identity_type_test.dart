import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';

void main() {
  group('GuestIdentityType Tests', () {
    test('has expected enum values and properties', () {
      expect(GuestIdentityType.ktp.code, 'KTP');
      expect(GuestIdentityType.ktp.label, 'KTP');

      expect(GuestIdentityType.sim.code, 'SIM');
      expect(GuestIdentityType.sim.label, 'SIM');

      expect(GuestIdentityType.paspor.code, 'PASPOR');
      expect(GuestIdentityType.paspor.label, 'Paspor');

      expect(GuestIdentityType.lainnya.code, 'LAINNYA');
      expect(GuestIdentityType.lainnya.label, 'Lainnya');
    });

    test('allowedCodes returns all valid backend codes', () {
      expect(
        GuestIdentityType.allowedCodes,
        ['KTP', 'SIM', 'PASPOR', 'LAINNYA'],
      );
    });

    test('tryFromCode parses codes correctly', () {
      expect(GuestIdentityType.tryFromCode('KTP'), GuestIdentityType.ktp);
      expect(GuestIdentityType.tryFromCode('ktp'), GuestIdentityType.ktp);
      expect(GuestIdentityType.tryFromCode(' SIM '), GuestIdentityType.sim);
      expect(
        GuestIdentityType.tryFromCode('paspor'),
        GuestIdentityType.paspor,
      );
      expect(
        GuestIdentityType.tryFromCode('lainnya'),
        GuestIdentityType.lainnya,
      );
      expect(GuestIdentityType.tryFromCode(null), isNull);
      expect(GuestIdentityType.tryFromCode('UNKNOWN'), isNull);
    });

    test('CreateGuestParams delegates allowedIdentityTypes to enum', () {
      expect(
        CreateGuestParams.allowedIdentityTypes,
        GuestIdentityType.allowedCodes,
      );
    });
  });
}
