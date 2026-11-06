import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';

void main() {
  group('EnvConfig Security Guardrails Tests', () {
    tearDown(dotenv.clean);

    group('Production (AppEnvironment.prod)', () {
      test('passes when production configuration is fully valid', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://api.kawalo.com/api/v1
APP_NAME=Kawalo Mobile
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          returnsNormally,
        );
      });

      test('passes when production uses custom domain', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://api.perusahaan.co.id/api/v1
APP_NAME=Kawalo Enterprise
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          returnsNormally,
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL is not '
          'HTTPS', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=http://api.kawalo.com/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL is '
          'localhost', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://localhost:8080/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL is private '
          'LAN IP', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://192.168.1.100:8443/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL has dev '
          'label', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://api-dev.kawalo.com/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL has staging '
          'label', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://staging.perusahaan.co.id/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when host format is invalid',
          () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://invalid..host/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when onboarding persistence '
          'is false', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://api.kawalo.com/api/v1
ENABLE_ONBOARDING_PERSISTENCE=false
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.prod),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });
    });

    group('Staging (AppEnvironment.staging)', () {
      test('passes when staging configuration is valid', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://api-stg.kawalo.com/api/v1
APP_NAME=Kawalo Staging
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.staging),
          returnsNormally,
        );
      });

      test('passes when staging uses any custom valid remote domain', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://qa-gateway.customdomain.org/api/v1
APP_NAME=Kawalo QA
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.staging),
          returnsNormally,
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL is not '
          'HTTPS', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=http://api-stg.kawalo.com/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.staging),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });

      test(
          'throws ConfigurationSecurityException when staging points to '
          'localhost', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://localhost:8080/api/v1
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.staging),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });
    });

    group('Development (AppEnvironment.dev)', () {
      test('passes when dev configuration uses LAN IP endpoint', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=http://172.27.78.232:3000/api
APP_NAME=Kawalo Dev
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.dev),
          returnsNormally,
        );
      });

      test('passes when dev configuration uses localhost or emulator', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=http://10.0.2.2:3000/api
APP_NAME=Kawalo Dev
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.dev),
          returnsNormally,
        );
      });

      test('passes when dev configuration uses any custom domain', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://dev.perusahaan.co.id/api
APP_NAME=Kawalo Dev
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.dev),
          returnsNormally,
        );
      });

      test(
          'throws ConfigurationSecurityException when API_BASE_URL is '
          'malformed', () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=not-a-valid-url
ENABLE_ONBOARDING_PERSISTENCE=true
''',
        );

        expect(
          () => EnvConfig.validateConfiguration(AppEnvironment.dev),
          throwsA(isA<ConfigurationSecurityException>()),
        );
      });
    });

    group('Initialization Validation Bypass', () {
      test('validateSecurity: false allows loading without throwing', () async {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=http://insecure.test/api/v1
''',
        );

        await expectLater(
          EnvConfig.init(
            AppEnvironment.prod,
            validateSecurity: false,
          ),
          completes,
        );
      });
    });

    group('JWT_PUBLIC_KEY Strict Requirement Tests', () {
      test('throws StateError when JWT_PUBLIC_KEY is missing in environment',
          () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL=https://api.kawalo.com/api/v1
APP_NAME=Kawalo Mobile
''',
        );

        expect(
          () => EnvConfig.jwtPublicKeyPem,
          throwsA(isA<StateError>()),
        );
      });

      test(
        'returns normalized PEM when JWT_PUBLIC_KEY is defined in environment',
        () {
          dotenv.loadFromString(
            envString: r'''
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A\n-----END PUBLIC KEY-----"
''',
          );

          const expectedPem = '-----BEGIN PUBLIC KEY-----\n'
              'MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A\n'
              '-----END PUBLIC KEY-----';

          expect(
            EnvConfig.jwtPublicKeyPem,
            equals(expectedPem),
          );
        },
      );
    });
  });
}
