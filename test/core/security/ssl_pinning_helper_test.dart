import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/security/ssl_pinning_helper.dart';

class FakeX509Certificate implements X509Certificate {
  FakeX509Certificate({
    required this.der,
    DateTime? startValidity,
    DateTime? endValidity,
  }) : startValidity =
           startValidity ?? DateTime.now().subtract(const Duration(days: 1)),
       endValidity =
           endValidity ?? DateTime.now().add(const Duration(days: 30));

  @override
  final Uint8List der;

  @override
  final DateTime startValidity;

  @override
  final DateTime endValidity;

  @override
  String get issuer => 'CN=Kawalo Test CA';

  @override
  String get subject => 'CN=api.kawalo.com';

  @override
  String get pem => '';

  @override
  Uint8List get sha1 => Uint8List(20);
}

Uint8List buildMinimalCertDer({
  required Uint8List spkiBytes,
  bool includeVersion = true,
  int serialTag = 0x02,
  int sigTag = 0x30,
}) {
  final versionBytes = includeVersion
      ? [0xa0, 0x03, 0x02, 0x01, 0x02] // [0] EXPLICIT v3
      : <int>[];
  final serialBytes = [serialTag, 0x01, 0x01]; // INTEGER 1
  final sigAlgBytes = [sigTag, 0x02, 0x05, 0x00]; // SEQUENCE NULL
  final issuerBytes = [0x30, 0x02, 0x05, 0x00]; // SEQUENCE NULL
  final validityBytes = [0x30, 0x02, 0x05, 0x00]; // SEQUENCE NULL
  final subjectBytes = [0x30, 0x02, 0x05, 0x00]; // SEQUENCE NULL

  final tbsContent = [
    ...versionBytes,
    ...serialBytes,
    ...sigAlgBytes,
    ...issuerBytes,
    ...validityBytes,
    ...subjectBytes,
    ...spkiBytes,
  ];
  final tbsDer = [0x30, tbsContent.length, ...tbsContent];

  final certSigAlg = [0x30, 0x02, 0x05, 0x00];
  final certSigValue = [0x03, 0x02, 0x00, 0x00];

  final certContent = [...tbsDer, ...certSigAlg, ...certSigValue];

  return Uint8List.fromList([0x30, certContent.length, ...certContent]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSpki = Uint8List.fromList([
    0x30,
    0x05,
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
  ]);
  final sampleCertDer = buildMinimalCertDer(spkiBytes: sampleSpki);
  final expectedSpkiPin = base64.encode(sha256.convert(sampleSpki).bytes);
  final expectedCertPin = base64.encode(sha256.convert(sampleCertDer).bytes);

  group('SslPinningHelper ASN.1 DER Parser Tests', () {
    test('extractSpkiDer returns null on invalid or empty DER', () {
      expect(SslPinningHelper.extractSpkiDer([]), isNull);
      expect(SslPinningHelper.extractSpkiDer([0x00, 0x01, 0x02]), isNull);
    });

    test('extractSpkiDer returns null on indefinite length (0x80)', () {
      expect(SslPinningHelper.extractSpkiDer([0x30, 0x80, 0x00, 0x00]), isNull);
    });

    test('extractSpkiDer returns null on excessive length bytes (>4)', () {
      expect(
        SslPinningHelper.extractSpkiDer([0x30, 0x85, 0x01, 0x02, 0x03]),
        isNull,
      );
    });

    test(
      'extractSpkiDer returns null on non-minimal DER length (leading zero)',
      () {
        expect(
          SslPinningHelper.extractSpkiDer([0x30, 0x82, 0x00, 0x05, 0x01]),
          isNull,
        );
      },
    );

    test('extractSpkiDer returns null on root SEQUENCE buffer overflow', () {
      expect(SslPinningHelper.extractSpkiDer([0x30, 0x0A, 0x01, 0x02]), isNull);
    });

    test(
      'extractSpkiDer returns null on missing or malformed mandatory field',
      () {
        // serialNumber bukan INTEGER (0x02)
        final malformedCert = buildMinimalCertDer(
          spkiBytes: sampleSpki,
          serialTag: 0x05,
        );
        expect(SslPinningHelper.extractSpkiDer(malformedCert), isNull);
      },
    );

    test(
      'extractSpkiDer correctly extracts SPKI from valid DER certificate',
      () {
        final extracted = SslPinningHelper.extractSpkiDer(sampleCertDer);
        expect(extracted, isNotNull);
        expect(extracted, equals(sampleSpki));
      },
    );

    test('extractSpkiDer supports v1 certificates without version field', () {
      final v1Cert = buildMinimalCertDer(
        spkiBytes: sampleSpki,
        includeVersion: false,
      );
      final extracted = SslPinningHelper.extractSpkiDer(v1Cert);
      expect(extracted, isNotNull);
      expect(extracted, equals(sampleSpki));
    });
  });

  group('SslPinningHelper validateCertificate Security Tests', () {
    setUp(() async {
      await EnvConfig.init(AppEnvironment.prod, validateSecurity: false);
    });

    test('bypasses validation when not enforcing in debug/dev', () {
      final isValid = SslPinningHelper.validateCertificate(
        null,
        'api.kawalo.com',
        443,
      );
      expect(isValid, isTrue);
    });

    test(
      'returns false (fail-closed) when certificate is null and enforced',
      () {
        final isValid = SslPinningHelper.validateCertificate(
          null,
          'api.kawalo.com',
          443,
          enforceInDebug: true,
        );
        expect(isValid, isFalse);
      },
    );

    test('returns false when certificate is expired', () {
      final cert = FakeX509Certificate(
        der: sampleCertDer,
        startValidity: DateTime.now().subtract(const Duration(days: 30)),
        endValidity: DateTime.now().subtract(const Duration(days: 1)),
      );
      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'api.kawalo.com',
        443,
        primaryPin: 'sha256/$expectedSpkiPin',
        enforceInDebug: true,
      );
      expect(isValid, isFalse);
    });

    test('returns false when host does not match expectedHost', () {
      final cert = FakeX509Certificate(der: sampleCertDer);
      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'evil-proxy.com',
        443,
        expectedHost: 'api.kawalo.com',
        primaryPin: 'sha256/$expectedSpkiPin',
        enforceInDebug: true,
      );
      expect(isValid, isFalse);
    });

    test(
      'returns false (fail-closed) when no pins are configured in non-dev',
      () {
        final cert = FakeX509Certificate(der: sampleCertDer);
        final isValid = SslPinningHelper.validateCertificate(
          cert,
          'api.kawalo.com',
          443,
          primaryPin: '',
          backupPin: '',
          enforceInDebug: true,
        );
        expect(isValid, isFalse);
      },
    );

    test('returns true when SPKI pin matches primaryPin with prefix', () {
      final cert = FakeX509Certificate(der: sampleCertDer);
      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'api.kawalo.com',
        443,
        primaryPin: 'sha256/$expectedSpkiPin',
        enforceInDebug: true,
      );
      expect(isValid, isTrue);
    });

    test('returns true when SPKI pin matches backupPin without prefix', () {
      final cert = FakeX509Certificate(der: sampleCertDer);
      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'api.kawalo.com',
        443,
        primaryPin: 'sha256/bogusPin=',
        backupPin: expectedSpkiPin,
        enforceInDebug: true,
      );
      expect(isValid, isTrue);
    });

    test('returns true when cert DER pin matches fallback', () {
      // Buat cert dengan SPKI malformed yang gagal diekstrak
      final malformedCert = buildMinimalCertDer(
        spkiBytes: sampleSpki,
        sigTag: 0x05, // rusak sig alg agar extractSpkiDer return null
      );
      final malformedCertPin = base64.encode(
        sha256.convert(malformedCert).bytes,
      );
      final cert = FakeX509Certificate(der: malformedCert);

      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'api.kawalo.com',
        443,
        primaryPin: 'sha256/$malformedCertPin',
        enforceInDebug: true,
      );
      expect(isValid, isTrue);
    });

    test('returns true when cert DER pin matches directly on full cert', () {
      final cert = FakeX509Certificate(der: sampleCertDer);
      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'api.kawalo.com',
        443,
        primaryPin: 'sha256/$expectedCertPin',
        enforceInDebug: true,
      );
      expect(isValid, isTrue);
    });

    test('returns false when neither SPKI nor certPin matches', () {
      final cert = FakeX509Certificate(der: sampleCertDer);
      final isValid = SslPinningHelper.validateCertificate(
        cert,
        'api.kawalo.com',
        443,
        primaryPin: 'sha256/wrongPin=',
        backupPin: 'sha256/anotherWrongPin=',
        enforceInDebug: true,
      );
      expect(isValid, isFalse);
    });
  });
}
