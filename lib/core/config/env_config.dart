import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';

/// Konfigurasi environment terpadu aplikasi Kawalo Mobile.
///
/// Menyediakan resolusi konfigurasi berlapis (*layered configuration*):
/// 1. `--dart-define` (prioritas tertinggi / compile-time).
/// 2. File `.env` aktif via `flutter_dotenv` (prioritas kedua / runtime).
/// 3. Nilai default aman sesuai environment.
class EnvConfig {
  EnvConfig._();

  // --- Environment Variable Keys ---
  static const _keyApiBaseUrl = 'API_BASE_URL';
  static const _keyAppName = 'APP_NAME';
  static const _keyEnableOnboardingPersistence =
      'ENABLE_ONBOARDING_PERSISTENCE';
  static const _keyJwtPublicKey = 'JWT_PUBLIC_KEY';
  static const _keySslPinPrimary = 'SSL_PIN_PRIMARY';
  static const _keySslPinBackup = 'SSL_PIN_BACKUP';
  static const _keyOfficialAppSignature = 'OFFICIAL_APP_SIGNATURE';

  // --- Defaults & Guardrail Constants ---
  static const _defaultAppName = 'Kawalo Mobile';
  static const _httpsScheme = 'https';
  static const _httpScheme = 'http';

  // --- Regex Sintaks Host & IP (Domain-Agnostic, Precompiled) ---
  static final _fqdnRegex = RegExp(
    r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}$',
  );
  static final _ipv4Regex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
    r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );
  static final _trailingSlashRegex = RegExp(r'/+$');
  static final _privateSubnet172Regex = RegExp(
    r'^172\.(1[6-9]|2[0-9]|3[0-1])\.',
  );

  static const Set<String> _nonProdKeywords = {
    'dev',
    'staging',
    'stg',
    'test',
    'sandbox',
    'local',
    'qa',
    'uat',
  };

  /// Backing field untuk target environment yang sedang aktif.
  static AppEnvironment? _environment;

  /// Target environment yang sedang aktif.
  ///
  /// Melempar [StateError] jika diakses sebelum [init] dipanggil.
  static AppEnvironment get environment {
    final env = _environment;
    if (env == null) {
      throw StateError(
        'EnvConfig belum diinisialisasi. Panggil EnvConfig.init() terlebih '
        'dahulu sebelum mengakses environment.',
      );
    }
    return env;
  }

  /// Menetapkan environment secara langsung (terutama untuk unit tests).
  static set environment(AppEnvironment env) => _environment = env;

  /// Memeriksa apakah [EnvConfig] telah berhasil diinisialisasi.
  static bool get isInitialized => _environment != null;

  /// Mereset state environment untuk keperluan pengujian terisolasi.
  @visibleForTesting
  static void resetForTesting() {
    _environment = null;
  }

  /// Menginisialisasi environment, memuat file `.env`, dan memvalidasi
  /// guardrails keamanan.
  static Future<void> init(
    AppEnvironment env, {
    bool validateSecurity = true,
  }) async {
    _environment = env;

    try {
      await dotenv.load(fileName: env.envFileName);
    } catch (_) {
      // Fallback jika file tidak ada di assets atau menggunakan --dart-define secara eksklusif
    }

    if (validateSecurity) {
      validateConfiguration(env);
    }
  }

  /// Memvalidasi konfigurasi terhadap guardrails keamanan sesuai target
  /// environment secara domain-agnostik. Melempar
  /// [ConfigurationSecurityException] jika konfigurasi melanggar aturan.
  static void validateConfiguration(AppEnvironment env) {
    final url = apiBaseUrl.trim();
    if (url.isEmpty) {
      throw const ConfigurationSecurityException(
        'API_BASE_URL wajib dikonfigurasi dan tidak boleh kosong.',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      throw ConfigurationSecurityException(
        'API_BASE_URL ($url) tidak valid. Wajib berupa format URI dengan '
        'skema dan host.',
      );
    }

    final host = uri.host.trim().toLowerCase();
    final scheme = uri.scheme.toLowerCase();
    final isHttps = scheme == _httpsScheme;

    if (scheme != _httpScheme && scheme != _httpsScheme) {
      throw ConfigurationSecurityException(
        'Protokol pada API_BASE_URL ($scheme) tidak didukung. '
        'Hanya HTTP dan HTTPS yang diizinkan.',
      );
    }

    if (uri.hasPort && (uri.port <= 0 || uri.port > 65535)) {
      throw ConfigurationSecurityException(
        'Port pada API_BASE_URL (${uri.port}) berada di luar rentang '
        'valid (1-65535).',
      );
    }

    final isValidHost =
        host == 'localhost' ||
        host == '10.0.2.2' ||
        _fqdnRegex.hasMatch(host) ||
        _ipv4Regex.hasMatch(host) ||
        (host.startsWith('[') && host.endsWith(']'));

    if (!isValidHost) {
      throw ConfigurationSecurityException(
        'Host pada API_BASE_URL ($host) tidak memiliki format domain (FQDN) '
        'atau IP yang valid.',
      );
    }

    switch (env) {
      case AppEnvironment.prod:
        if (!isHttps) {
          throw const ConfigurationSecurityException(
            'Produksi HARUS menggunakan protokol HTTPS pada API_BASE_URL '
            'untuk menjamin keamanan transmisi data.',
          );
        }

        if (_isLoopbackOrLocalhost(host)) {
          throw ConfigurationSecurityException(
            'Produksi TIDAK boleh mengarah ke endpoint localhost atau '
            'loopback ($host).',
          );
        }

        if (_isPrivateSubnet(host)) {
          throw ConfigurationSecurityException(
            'Produksi TIDAK boleh mengarah ke IP subnet privat LAN ($host).',
          );
        }

        if (_hasNonProdLabels(host)) {
          throw ConfigurationSecurityException(
            'Produksi TIDAK boleh menggunakan endpoint development, staging, '
            'atau test ($host).',
          );
        }

        if (!enableOnboardingPersistence) {
          throw const ConfigurationSecurityException(
            'Produksi HARUS mengaktifkan persistensi onboarding '
            '(ENABLE_ONBOARDING_PERSISTENCE harus true).',
          );
        }

      case AppEnvironment.staging:
        if (!isHttps) {
          throw const ConfigurationSecurityException(
            'Staging HARUS menggunakan protokol HTTPS pada API_BASE_URL.',
          );
        }

        if (_isLoopbackOrLocalhost(host)) {
          throw ConfigurationSecurityException(
            'Staging TIDAK boleh mengarah ke localhost atau loopback ($host). '
            'Harus mengarah ke server remote staging.',
          );
        }

      case AppEnvironment.dev:
        // Development bebas menggunakan HTTP/HTTPS, localhost, IP LAN/emulator,
        // maupun remote dev domain apa pun asalkan berformat valid.
        break;
    }
  }

  static bool _isLoopbackOrLocalhost(String host) {
    return host == 'localhost' ||
        host == '10.0.2.2' ||
        host == '::1' ||
        host == '[::1]' ||
        host.startsWith('127.');
  }

  static bool _isPrivateSubnet(String host) {
    if (_isLoopbackOrLocalhost(host)) return true;
    if (host.startsWith('10.') ||
        host.startsWith('192.168.') ||
        host.startsWith('169.254.')) {
      return true;
    }
    return _privateSubnet172Regex.hasMatch(host);
  }

  static bool _hasNonProdLabels(String host) {
    final parts = host.split('.');
    return parts.any(
      (part) =>
          _nonProdKeywords.contains(part) ||
          part.startsWith('dev-') ||
          part.endsWith('-dev') ||
          part.startsWith('stg-') ||
          part.endsWith('-stg') ||
          part.startsWith('api-dev') ||
          part.startsWith('api-stg') ||
          part.startsWith('qa-') ||
          part.endsWith('-qa') ||
          part.startsWith('uat-') ||
          part.endsWith('-uat'),
    );
  }

  // --- Getters ---

  /// URL dasar API backend Kawalo.
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment(_keyApiBaseUrl);
    final rawUrl = _resolve(fromDefine, _keyApiBaseUrl, defaultValue: '');
    return rawUrl.replaceAll(_trailingSlashRegex, '');
  }

  /// Nama tampilan aplikasi.
  static String get appName {
    const fromDefine = String.fromEnvironment(_keyAppName);
    return _resolve(fromDefine, _keyAppName, defaultValue: _defaultAppName);
  }

  /// Menentukan apakah alur persistensi onboarding diaktifkan.
  static bool get enableOnboardingPersistence {
    const fromDefine = String.fromEnvironment(_keyEnableOnboardingPersistence);
    return _resolveBool(
      fromDefine,
      _keyEnableOnboardingPersistence,
      defaultValue: true,
    );
  }

  /// Public Key RSA 4096-bit resmi backend untuk memverifikasi tanda tangan
  /// RS256 token JWT secara asimetris di client (mencegah pemalsuan token).
  ///
  /// Wajib didefinisikan pada file environment (`.env`).
  /// Tidak ada nilai default atau fallback demi keamanan kriptografis.
  static String get jwtPublicKeyPem {
    const fromDefine = String.fromEnvironment(_keyJwtPublicKey);
    final raw = _resolveNullable(fromDefine, _keyJwtPublicKey);
    if (raw != null && raw.isNotEmpty) {
      return raw.replaceAll(r'\n', '\n');
    }
    throw StateError(
      'Konfigurasi JWT_PUBLIC_KEY wajib disediakan di environment (.env)',
    );
  }

  /// Shortcut environment aktif.
  static bool get isDev => environment.isDev;
  static bool get isStaging => environment.isStaging;
  static bool get isProd => environment.isProd;

  /// SHA-256 SPKI SSL Pinning utama.
  static String? get sslPinPrimary {
    const fromDefine = String.fromEnvironment(_keySslPinPrimary);
    return _resolveNullable(fromDefine, _keySslPinPrimary);
  }

  /// SHA-256 SPKI SSL Pinning cadangan.
  static String? get sslPinBackup {
    const fromDefine = String.fromEnvironment(_keySslPinBackup);
    return _resolveNullable(fromDefine, _keySslPinBackup);
  }

  /// SHA-256 Signature Sertifikat rilis resmi aplikasi.
  static String? get officialAppSignature {
    const fromDefine = String.fromEnvironment(_keyOfficialAppSignature);
    return _resolveNullable(fromDefine, _keyOfficialAppSignature);
  }

  // --- Internal Resolvers ---

  static String _resolve(
    String fromDefine,
    String key, {
    required String defaultValue,
  }) {
    return _resolveNullable(fromDefine, key) ?? defaultValue;
  }

  static String? _resolveNullable(String fromDefine, String key) {
    if (fromDefine.isNotEmpty) {
      final trimmed = _stripQuotes(fromDefine.trim());
      if (trimmed.isNotEmpty) return trimmed;
    }
    if (dotenv.isInitialized) {
      final raw = dotenv.maybeGet(key)?.trim();
      if (raw != null && raw.isNotEmpty) {
        final trimmed = _stripQuotes(raw);
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }

  static String _stripQuotes(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  static bool _resolveBool(
    String fromDefine,
    String key, {
    required bool defaultValue,
  }) {
    final value = _resolveNullable(fromDefine, key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }
}
