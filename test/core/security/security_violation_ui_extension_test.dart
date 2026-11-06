import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:kawalo_mobile/core/security/presentation/extensions/security_violation_ui_extension.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';

void main() {
  group('SecurityViolationUiExtension Unit Tests', () {
    test('rootOrJailbreak maps to correct title, description, and icon', () {
      const violation = SecurityViolationType.rootOrJailbreak;

      expect(
        violation.displayTitle,
        equals('Perangkat tidak memenuhi standar keamanan'),
      );
      expect(
        violation.displayDescription,
        contains('telah dimodifikasi'),
      );
      expect(violation.icon, equals(KawaloVectors.shieldOffFilled));
    });

    test('mockLocation maps to correct title, description, and icon', () {
      const violation = SecurityViolationType.mockLocation;

      expect(
        violation.displayTitle,
        equals('Lokasi tiruan terdeteksi'),
      );
      expect(
        violation.displayDescription,
        contains('penyedia lokasi tiruan'),
      );
      expect(violation.icon, equals(KawaloVectors.gpsDisconnectedFilled));
    });

    test('unofficialStore maps to correct title, description, and icon', () {
      const violation = SecurityViolationType.unofficialStore;

      expect(
        violation.displayTitle,
        equals('Aplikasi tidak resmi terdeteksi'),
      );
      expect(
        violation.displayDescription,
        contains('toko aplikasi resmi'),
      );
      expect(violation.icon, equals(KawaloVectors.shieldXFilled));
    });
  });
}
