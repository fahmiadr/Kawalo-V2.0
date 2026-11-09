import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';

/// Utilitas ringan murni Dart untuk membaca dan memvalidasi token JWT
/// secara lokal dan hybrid dynamic JWKS.
class JwtUtils {
  JwtUtils._();

  /// Memeriksa apakah token JWT telah kedaluwarsa secara lokal.
  ///
  /// [buffer] adalah toleransi selisih waktu (clock skew) sebelum masa berlaku
  /// benar-benar habis (default: 60 detik).
  ///
  /// Bila token berformat non-JWT atau tidak valid, method ini
  /// mengembalikan `true` (dianggap expired/invalid).
  static bool isExpired(
    String token, {
    Duration buffer = const Duration(seconds: 60),
  }) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return true;

    final parts = trimmed.split('.');
    if (parts.length != 3) {
      return true;
    }

    try {
      final payload = decodePayload(trimmed);
      if (payload == null) return true;

      final exp = payload['exp'];
      if (exp is num) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(
          exp.toInt() * 1000,
        );
        final threshold = DateTime.now().add(buffer);
        return threshold.isAfter(expiryDate);
      }
      return false;
    } on Object catch (_) {
      return true;
    }
  }

  /// Mengekstrak JOSE header JWT sebagai JSON map tanpa verifikasi
  /// kriptografis.
  static Map<String, dynamic>? decodeHeader(String token) {
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3) return null;

      final headerNormalized = base64Url.normalize(parts[0]);
      final headerString = utf8.decode(base64Url.decode(headerNormalized));
      final decoded = jsonDecode(headerString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on Object catch (_) {
      return null;
    }
  }

  /// Mengekstrak key ID (`kid`) dari header token JWT bila tersedia.
  static String? extractKid(String token) {
    final header = decodeHeader(token);
    return header?['kid'] as String?;
  }

  /// Mengekstrak payload JSON claims dari token JWT (bagian ke-2) tanpa
  /// verifikasi tanda tangan kriptografis.
  ///
  /// Mengembalikan `null` bila struktur token cacat atau tidak dapat didecode.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3) return null;

      final payloadNormalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadNormalized));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on Object catch (_) {
      return null;
    }
  }

  /// Menormalisasi string PEM publik RSA agar selalu berformat standar SPKI:
  /// - Mengonversi escape newline (`\n`) menjadi karakter newline asli
  /// - Menangani string satu baris (single-line) dengan memecah base64 per
  ///   64 karakter
  /// - Menghapus karakter carriage return (`\r`)
  static String normalizePem(String pem) {
    final clean = pem.replaceAll(r'\n', '\n').replaceAll('\r', '').trim();
    if (!clean.contains('\n')) {
      const beginMarker = '-----BEGIN PUBLIC KEY-----';
      const endMarker = '-----END PUBLIC KEY-----';
      if (clean.contains(beginMarker) && clean.contains(endMarker)) {
        final base64Part = clean
            .replaceAll(beginMarker, '')
            .replaceAll(endMarker, '')
            .replaceAll(RegExp(r'\s+'), '');
        final buffer = StringBuffer('$beginMarker\n');
        for (var i = 0; i < base64Part.length; i += 64) {
          final end = (i + 64 > base64Part.length) ? base64Part.length : i + 64;
          buffer.writeln(base64Part.substring(i, end));
        }
        buffer.writeln(endMarker);
        return buffer.toString();
      }
    }
    return clean;
  }

  /// Memverifikasi tanda tangan kriptografis RS256 token JWT secara sinkron
  /// menggunakan [publicKeyPem] spesifik atau [EnvConfig.jwtPublicKeyPem].
  ///
  /// Mengembalikan payload jika valid, atau `null` bila tanda tangan tidak
  /// valid, token dipalsukan/dimodifikasi (tampered), atau format token rusak.
  ///
  /// Parameter [checkExpiresIn] menentukan apakah masa kedaluwarsa token
  /// harus diperiksa saat verifikasi tanda tangan (default: `true`).
  /// Bila diset `false`, integritas tanda tangan tetap divalidasi penuh
  /// namun token yang kedaluwarsa tetap dapat di-decode untuk kebutuhan
  /// rehidrasi sesi dan silent token refresh.
  static Map<String, dynamic>? verifyAndDecodeSync(
    String token, {
    String? publicKeyPem,
    bool checkExpiresIn = true,
  }) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final pem = publicKeyPem ?? EnvConfig.jwtPublicKeyPem;
      final key = RSAPublicKey(normalizePem(pem));
      final jwt = JWT.verify(trimmed, key, checkExpiresIn: checkExpiresIn);
      if (jwt.payload is Map) {
        return (jwt.payload as Map).cast<String, dynamic>();
      }
      return null;
    } on JWTException catch (_) {
      return null;
    } on Object catch (_) {
      return null;
    }
  }

  /// Memverifikasi tanda tangan kriptografis RS256 token JWT secara hybrid:
  ///
  /// 1. **Fast Path**: Jika [publicKeyPem] diberikan, verifikasi langsung
  ///    menggunakan kunci tersebut.
  /// 2. **JWKS Resolution**: Jika [jwksService] diberikan, ekstrak `kid`.
  ///    Ambil kunci dari cache memori/secure storage.
  /// 3. **Dynamic Key Rotation Fallback**: Bila kunci untuk `kid` belum ada
  ///    atau verifikasi gagal, panggil `jwksService.getPublicKeyPemForKid`
  ///    dengan `forceRefresh: true` lalu coba verifikasi ulang.
  /// 4. **Env Fallback**: Jika tidak menggunakan JWKS atau jaringan gagal,
  ///    verifikasi dengan [EnvConfig.jwtPublicKeyPem].
  ///
  /// Mengembalikan payload jika valid, atau `null` jika tanda tangan salah.
  static Future<Map<String, dynamic>?> verifyAndDecode(
    String token, {
    String? publicKeyPem,
    JwksService? jwksService,
    bool checkExpiresIn = true,
  }) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('.');
    if (parts.length != 3) {
      return null;
    }

    // Kasus 1: Kunci spesifik diberikan secara eksplisit
    if (publicKeyPem != null && publicKeyPem.isNotEmpty) {
      return verifyAndDecodeSync(
        trimmed,
        publicKeyPem: publicKeyPem,
        checkExpiresIn: checkExpiresIn,
      );
    }

    // Kasus 2: Gunakan JwksService untuk resolusi hybrid
    if (jwksService != null) {
      final kid = extractKid(trimmed);

      // Coba ambil dari cache (fast-path tanpa latency jaringan)
      var keyPem = await jwksService.getPublicKeyPemForKid(kid);
      if (keyPem != null) {
        final result = verifyAndDecodeSync(
          trimmed,
          publicKeyPem: keyPem,
          checkExpiresIn: checkExpiresIn,
        );
        if (result != null) {
          if (kid != null) jwksService.cacheKey(kid, keyPem);
          return result;
        }
      }

      // Jika gagal atau kid belum dikenal, refresh JWKS dari server
      keyPem = await jwksService.getPublicKeyPemForKid(kid, forceRefresh: true);
      if (keyPem != null) {
        final result = verifyAndDecodeSync(
          trimmed,
          publicKeyPem: keyPem,
          checkExpiresIn: checkExpiresIn,
        );
        if (result != null) {
          if (kid != null) jwksService.cacheKey(kid, keyPem);
          return result;
        }
      }
    }

    // Kasus 3: Fallback ke kunci publik di EnvConfig
    final fallbackResult = verifyAndDecodeSync(
      trimmed,
      checkExpiresIn: checkExpiresIn,
    );
    if (fallbackResult != null && jwksService != null) {
      final kid = extractKid(trimmed);
      if (kid != null) {
        try {
          jwksService.cacheKey(kid, EnvConfig.jwtPublicKeyPem);
        } on Object catch (_) {}
      }
    }
    return fallbackResult;
  }
}
