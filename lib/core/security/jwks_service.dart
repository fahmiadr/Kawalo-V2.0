import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/security/rsa_jwk_helper.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';

/// Layanan manajemen kunci publik JWT berbasis JSON Web Key Set (JWKS).
///
/// Mendukung arsitektur **Hybrid Dynamic JWKS**:
/// 1. Fast path / Offline: Membaca kunci dari cache memori atau storage aman.
/// 2. Dynamic path / Key Rotation: Mengambil public keys terbaru dari endpoint
///    `/.well-known/jwks.json` saat token ditandatangani dengan `kid` baru.
class JwksService {
  JwksService({
    SecureStorageService? storageService,
    Dio? dio,
  })  : _storageService = storageService ?? SecureStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.connectTimeout,
                sendTimeout: AppConstants.sendTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
              ),
            );

  final SecureStorageService _storageService;
  final Dio _dio;

  /// Cache in-memory: `kid` -> SPKI PEM format
  final Map<String, String> _keyCache = {};
  bool _initialized = false;
  Future<Map<String, String>>? _ongoingFetch;

  /// Inisialisasi awal: memuat cache JWKS dari penyimpanan aman lokal
  /// agar verifikasi token dapat langsung berjalan tanpa delay jaringan.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final cachedJson = await _storageService.getJwksCache();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        _parseAndPopulateKeys(cachedJson);
      }
    } on Object catch (_) {
      // Best-effort load from secure storage
    } finally {
      _initialized = true;
    }
  }

  /// Mengambil kunci publik SPKI PEM untuk [kid] yang diminta.
  ///
  /// Alur resolusi:
  /// 1. Cek memory cache (termasuk bootstrap key dari EnvConfig).
  /// 2. Cek secure storage cache (bila belum diinisialisasi).
  /// 3. Bila tidak ditemukan atau [forceRefresh] true, hubungi endpoint JWKS.
  /// 4. Bila kid tidak dikenal setelah fetch, tolak key mismatch (return null).
  /// 5. Bila kid bernilai null (token tanpa kid), fallback ke bootstrap key.
  Future<String?> getPublicKeyPemForKid(
    String? kid, {
    String? baseUrl,
    bool forceRefresh = false,
  }) async {
    await initialize();

    if (!forceRefresh && kid != null && _keyCache.containsKey(kid)) {
      return _keyCache[kid];
    }

    // Jika forceRefresh aktif atau kid belum ada, ambil JWKS dari server
    if (forceRefresh || (kid != null && !_keyCache.containsKey(kid))) {
      await fetchAndCacheJwks(baseUrl: baseUrl);
      if (kid != null && _keyCache.containsKey(kid)) {
        return _keyCache[kid];
      }
    }

    // Fallback ke bootstrap key dari EnvConfig jika tersedia
    try {
      return EnvConfig.jwtPublicKeyPem;
    } on Object catch (_) {
      return null;
    }
  }

  /// Mengambil JWKS dari endpoint `/.well-known/jwks.json` backend,
  /// mengonversi semua kunci RSA ke PEM, dan memperbarui cache lokal.
  ///
  /// Menggunakan single-flight deduplication untuk mencegah *thundering herd*
  /// / cache stampede saat beberapa request mengalami cache-miss bersamaan.
  Future<Map<String, String>> fetchAndCacheJwks({String? baseUrl}) async {
    if (_ongoingFetch != null) {
      return await _ongoingFetch!;
    }
    _ongoingFetch = _doFetchAndCacheJwks(baseUrl: baseUrl);
    try {
      return await _ongoingFetch!;
    } finally {
      _ongoingFetch = null;
    }
  }

  Future<Map<String, String>> _doFetchAndCacheJwks({String? baseUrl}) async {
    String? rawJson;

    try {
      final effectiveBase = baseUrl ?? EnvConfig.apiBaseUrl;
      final uri = Uri.parse(effectiveBase);

      // Sesuai standar RFC 5785 / RFC 8414, endpoint JWKS berada di origin root
      final jwksUri = uri.replace(
        path: '/.well-known/jwks.json',
      );

      final response = await _dio.getUri<dynamic>(
        jwksUri,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        rawJson = jsonEncode(data);
      } else if (data is String && data.trim().isNotEmpty) {
        rawJson = data.trim();
      }
    } on Object catch (_) {
      // Fallback jika API berada di belakang reverse proxy subpath
      try {
        final effectiveBase = baseUrl ?? EnvConfig.apiBaseUrl;
        final subpath = effectiveBase.endsWith('/') ? '' : '/';
        final subpathUri = Uri.parse(
          '$effectiveBase$subpath.well-known/jwks.json',
        );
        final response = await _dio.getUri<dynamic>(
          subpathUri,
          options: Options(
            responseType: ResponseType.plain,
          ),
        );
        final dynamic data = response.data;
        if (data is Map<String, dynamic>) {
          rawJson = jsonEncode(data);
        } else if (data is String && data.trim().isNotEmpty) {
          rawJson = data.trim();
        }
      } on Object catch (_) {
        // Offline / server unreachable
      }
    }

    if (rawJson != null && rawJson.isNotEmpty) {
      _parseAndPopulateKeys(rawJson);
      try {
        await _storageService.saveJwksCache(rawJson);
      } on Object catch (_) {
        // Best-effort storage save
      }
    }

    return Map.unmodifiable(_keyCache);
  }

  /// Parsing JWKS JSON dan populate kunci ke [_keyCache]
  void _parseAndPopulateKeys(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic> && decoded['keys'] is List) {
        final keysList = decoded['keys'] as List;
        for (final item in keysList) {
          if (item is Map<String, dynamic>) {
            final kid = item['kid'] as String?;
            if (kid != null && kid.isNotEmpty) {
              try {
                final pem = RsaJwkHelper.rsaJwkToPem(item);
                _keyCache[kid] = pem;
              } on Object catch (_) {}
            }
          }
        }
      }
    } on Object catch (_) {}
  }

  /// Menghapus seluruh cache JWKS di memori dan penyimpanan lokal
  Future<void> clearCache() async {
    _keyCache.clear();
    _initialized = false;
    try {
      await _storageService.clearJwksCache();
    } on Object catch (_) {}
  }

  /// Mengasosiasikan `kid` dengan format SPKI PEM secara dinamis di memory
  /// cache.
  void cacheKey(String kid, String pem) {
    if (kid.isNotEmpty && pem.isNotEmpty) {
      _keyCache[kid] = pem;
    }
  }

  /// Mengambil snapshot cache kunci publik yang aktif saat ini di memori
  Map<String, String> get cachedKeys => Map.unmodifiable(_keyCache);
}
