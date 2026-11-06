import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/security/device_integrity_service.dart';
import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceIntegrityPlatform extends Mock
    implements DeviceIntegrityPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDeviceIntegrityPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockDeviceIntegrityPlatform();
    DeviceIntegrityService.platform = mockPlatform;
    EnvConfig.environment = AppEnvironment.dev;

    // Default mock behavior
    when(() => mockPlatform.isJailbroken()).thenAnswer((_) async => false);
    when(() => mockPlatform.getInstallerStore())
        .thenAnswer((_) async => 'com.android.vending');
    when(() => mockPlatform.getBuildSignature())
        .thenAnswer((_) async => 'A1:B2:C3:D4');
    when(() => mockPlatform.targetPlatform).thenReturn(TargetPlatform.android);
  });

  tearDown(() {
    DeviceIntegrityService.platform = null;
    EnvConfig.resetForTesting();
  });

  group('DeviceIntegrityPlatform & Default Platform Tests', () {
    test('platform getter returns default platform when not mocked', () {
      DeviceIntegrityService.platform = null;
      expect(
        DeviceIntegrityService.platform,
        isA<DefaultDeviceIntegrityPlatform>(),
      );
      expect(
        DeviceIntegrityService.platform.targetPlatform,
        defaultTargetPlatform,
      );
    });
  });

  group('isInstalledFromOfficialStore Tests', () {
    test('returns true for official Android stores', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);

      for (final store in DeviceIntegrityService.officialAndroidStores) {
        when(() => mockPlatform.getInstallerStore())
            .thenAnswer((_) async => store);
        final result =
            await DeviceIntegrityService.isInstalledFromOfficialStore();
        expect(result, isTrue, reason: 'Failed for store: $store');
      }
    });

    test('returns false for unauthorized Android installer packages', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);

      final unauthorizedStores = [
        'com.google.fake.store',
        'com.android.chrome',
        'org.malicious.installer',
        '',
      ];

      for (final store in unauthorizedStores) {
        when(() => mockPlatform.getInstallerStore())
            .thenAnswer((_) async => store);
        final result =
            await DeviceIntegrityService.isInstalledFromOfficialStore();
        expect(result, isFalse, reason: 'Should fail for store: $store');
      }
    });

    test('returns false when installerStore is null on Android', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(
        () => mockPlatform.getInstallerStore(),
      ).thenAnswer((_) async => null);

      final result =
          await DeviceIntegrityService.isInstalledFromOfficialStore();
      expect(result, isFalse);
    });

    test('returns true for official iOS stores', () async {
      when(() => mockPlatform.targetPlatform).thenReturn(TargetPlatform.iOS);

      for (final store in DeviceIntegrityService.officialIosStores) {
        when(() => mockPlatform.getInstallerStore())
            .thenAnswer((_) async => store);
        final result =
            await DeviceIntegrityService.isInstalledFromOfficialStore();
        expect(result, isTrue, reason: 'Failed for iOS store: $store');
      }
    });

    test('returns false for unauthorized iOS installer or null receipt',
        () async {
      when(() => mockPlatform.targetPlatform).thenReturn(TargetPlatform.iOS);

      when(
        () => mockPlatform.getInstallerStore(),
      ).thenAnswer((_) async => null);
      expect(
        await DeviceIntegrityService.isInstalledFromOfficialStore(),
        isFalse,
      );

      when(() => mockPlatform.getInstallerStore())
          .thenAnswer((_) async => 'com.sideload.altstore');
      expect(
        await DeviceIntegrityService.isInstalledFromOfficialStore(),
        isFalse,
      );
    });

    test('returns true on non-mobile desktop or web platforms', () async {
      when(() => mockPlatform.targetPlatform).thenReturn(TargetPlatform.macOS);
      expect(
        await DeviceIntegrityService.isInstalledFromOfficialStore(),
        isTrue,
      );

      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.windows);
      expect(
        await DeviceIntegrityService.isInstalledFromOfficialStore(),
        isTrue,
      );
    });

    test('returns false when getInstallerStore throws an exception', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.getInstallerStore())
          .thenThrow(Exception('Platform error'));

      expect(
        await DeviceIntegrityService.isInstalledFromOfficialStore(),
        isFalse,
      );
    });
  });

  group('isSignatureValid Tests', () {
    test('always returns true for iOS platform', () async {
      when(() => mockPlatform.targetPlatform).thenReturn(TargetPlatform.iOS);

      final result = await DeviceIntegrityService.isSignatureValid(
        expectedSignature: 'ANY_SIG',
        enforceInDebug: true,
      );
      expect(result, isTrue);
    });

    test('bypasses signature check when in debug or dev by default', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.getBuildSignature())
          .thenAnswer((_) async => 'DIFFERENT_HASH');

      final result = await DeviceIntegrityService.isSignatureValid(
        expectedSignature: 'EXPECTED_HASH',
      );
      expect(result, isTrue);
    });

    test('returns true when expected signature is null or empty', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);

      expect(
        await DeviceIntegrityService.isSignatureValid(
          enforceInDebug: true,
        ),
        isTrue,
      );
      expect(
        await DeviceIntegrityService.isSignatureValid(
          expectedSignature: '   ',
          enforceInDebug: true,
        ),
        isTrue,
      );
    });

    test(
      'normalizes and matches Android signature with colons and casing',
      () async {
        when(
          () => mockPlatform.targetPlatform,
        ).thenReturn(TargetPlatform.android);
        when(() => mockPlatform.getBuildSignature())
            .thenAnswer((_) async => 'AA:BB:CC:DD:EE');

        final result = await DeviceIntegrityService.isSignatureValid(
          expectedSignature: 'aa:bb:cc:dd:ee',
          enforceInDebug: true,
        );
        expect(result, isTrue);

        final resultWithoutColons =
            await DeviceIntegrityService.isSignatureValid(
          expectedSignature: 'AABBCCDDEE',
          enforceInDebug: true,
        );
        expect(resultWithoutColons, isTrue);
      },
    );

    test('supports multiple comma-separated expected signatures', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.getBuildSignature())
          .thenAnswer((_) async => 'PLAY_STORE_HASH_123');

      final result = await DeviceIntegrityService.isSignatureValid(
        expectedSignature: 'UPLOAD_KEY_999, PLAY_STORE_HASH_123',
        enforceInDebug: true,
      );
      expect(result, isTrue);
    });

    test('returns false when signature does not match expected', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.getBuildSignature())
          .thenAnswer((_) async => 'DIFFERENT_HASH');

      final result = await DeviceIntegrityService.isSignatureValid(
        expectedSignature: 'EXPECTED_HASH',
        enforceInDebug: true,
      );
      expect(result, isFalse);
    });

    test('returns false when current build signature is empty', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.getBuildSignature()).thenAnswer((_) async => '');

      final result = await DeviceIntegrityService.isSignatureValid(
        expectedSignature: 'EXPECTED_HASH',
        enforceInDebug: true,
      );
      expect(result, isFalse);
    });

    test('returns false when getBuildSignature throws an exception', () async {
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.getBuildSignature())
          .thenThrow(Exception('Signature channel error'));

      final result = await DeviceIntegrityService.isSignatureValid(
        expectedSignature: 'EXPECTED_HASH',
        enforceInDebug: true,
      );
      expect(result, isFalse);
    });
  });

  group('checkIntegrity Integration Tests', () {
    test('bypasses integrity checks in dev environment by default', () async {
      EnvConfig.environment = AppEnvironment.dev;
      when(() => mockPlatform.isJailbroken()).thenAnswer((_) async => true);

      final violation = await DeviceIntegrityService.checkIntegrity();
      expect(violation, isNull);
    });

    test('detects rootOrJailbreak when enforceInDebug is enabled', () async {
      when(() => mockPlatform.isJailbroken()).thenAnswer((_) async => true);

      final violation = await DeviceIntegrityService.checkIntegrity(
        enforceInDebug: true,
      );
      expect(violation, SecurityViolationType.rootOrJailbreak);
    });

    test('detects unofficial store in production environment', () async {
      EnvConfig.environment = AppEnvironment.prod;
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.isJailbroken()).thenAnswer((_) async => false);
      when(() => mockPlatform.getInstallerStore())
          .thenAnswer((_) async => 'com.malicious.store');

      final violation = await DeviceIntegrityService.checkIntegrity(
        enforceInDebug: true,
      );
      expect(violation, SecurityViolationType.unofficialStore);
    });

    test('detects invalid signature in production environment', () async {
      EnvConfig.environment = AppEnvironment.prod;
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.isJailbroken()).thenAnswer((_) async => false);
      when(() => mockPlatform.getInstallerStore())
          .thenAnswer((_) async => 'com.android.vending');
      when(() => mockPlatform.getBuildSignature())
          .thenAnswer((_) async => 'INVALID_SIGNATURE');

      final violation = await DeviceIntegrityService.checkIntegrity(
        expectedSignature: 'OFFICIAL_KEY_123',
        enforceInDebug: true,
      );
      expect(violation, SecurityViolationType.unofficialStore);
    });

    test('returns null when device integrity is fully valid in production',
        () async {
      EnvConfig.environment = AppEnvironment.prod;
      when(
        () => mockPlatform.targetPlatform,
      ).thenReturn(TargetPlatform.android);
      when(() => mockPlatform.isJailbroken()).thenAnswer((_) async => false);
      when(() => mockPlatform.getInstallerStore())
          .thenAnswer((_) async => 'com.android.vending');
      when(() => mockPlatform.getBuildSignature())
          .thenAnswer((_) async => 'OFFICIAL_KEY_123');

      final violation = await DeviceIntegrityService.checkIntegrity(
        expectedSignature: 'OFFICIAL_KEY_123',
        enforceInDebug: true,
      );
      expect(violation, isNull);
    });

    test('handles exceptions gracefully with fail-safe by default', () async {
      when(() => mockPlatform.isJailbroken())
          .thenThrow(Exception('Native plugin failure'));

      final violation = await DeviceIntegrityService.checkIntegrity(
        enforceInDebug: true,
      );
      expect(violation, isNull);
    });

    test('returns rootOrJailbreak violation when failClosedOnException is true',
        () async {
      when(() => mockPlatform.isJailbroken())
          .thenThrow(Exception('Tampered hook crashed channel'));

      final violation = await DeviceIntegrityService.checkIntegrity(
        enforceInDebug: true,
        failClosedOnException: true,
      );
      expect(violation, SecurityViolationType.rootOrJailbreak);
    });
  });
}
