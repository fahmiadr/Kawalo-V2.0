import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';

/// Helper untuk validasi SSL/TLS Public Key Pinning (SPKI SHA-256).
///
/// **Catatan Arsitektur:**
/// Pada Dart `dart:io`, [HttpClient.badCertificateCallback] hanya dipanggil
/// ketika validasi TLS oleh sistem operasi/CA bawaan telah GAGAL, dan objek
/// [X509Certificate] yang disediakan HANYA merupakan sertifikat Leaf
/// (End-Entity), bukan rantai sertifikat (intermediate/root CA).
///
/// Oleh karena itu:
/// 1. Pin SHA-256 yang dikonfigurasi di environment WAJIB merupakan SPKI dari
///    sertifikat Leaf server backend resmi.
/// 2. Jika koneksi ditujukan ke host selain backend Kawalo atau tidak memiliki
///    pin valid yang cocok, sertifikat yang ditolak OS akan langsung ditolak
///    (fail-closed) demi mencegah serangan Man-in-the-Middle (MITM).
class SslPinningHelper {
  SslPinningHelper._();

  static const int _asn1Sequence = 0x30;
  static const int _asn1Integer = 0x02;
  static const int _asn1VersionContextTag = 0xa0;
  static const String _pinPrefix = 'sha256/';

  /// Memverifikasi sertifikat TLS server terhadap pin SPKI/Sertifikat SHA-256.
  ///
  /// Mengembalikan `true` jika:
  /// 1. Berada di lingkungan `Dev` atau `kDebugMode` (otomatis di-bypass).
  /// 2. Sertifikat masih dalam masa berlaku (`startValidity` <= now <=
  ///    `endValidity`).
  /// 3. Host yang diakses cocok dengan [expectedHost] (default: host dari
  ///    [EnvConfig.apiBaseUrl]).
  /// 4. Hash SPKI atau hash sertifikat DER cocok dengan [primaryPin] atau
  ///    [backupPin].
  ///
  /// Mengembalikan `false` (fail-closed) jika sertifikat null, kedaluwarsa,
  /// host tidak cocok, atau tidak ada pin valid yang terkonfigurasi.
  static bool validateCertificate(
    X509Certificate? cert,
    String host,
    int port, {
    String? primaryPin,
    String? backupPin,
    String? expectedHost,
    @visibleForTesting bool enforceInDebug = false,
  }) {
    // 1. Bypass otomatis pada lingkungan Dev atau mode Debug untuk kelancaran
    // pengembangan lokal (kecuali diuji secara spesifik dalam unit test)
    if (!enforceInDebug && (EnvConfig.isDev || kDebugMode)) {
      return true;
    }

    if (cert == null) {
      return false;
    }

    // 2. Verifikasi masa berlaku sertifikat (Not Before & Not After)
    final now = DateTime.now();
    if (now.isBefore(cert.startValidity) || now.isAfter(cert.endValidity)) {
      return false;
    }

    // 3. Verifikasi kesesuaian host (Domain Scoping)
    final targetHost = expectedHost ?? _resolveDefaultApiHost();
    if (targetHost != null && targetHost.isNotEmpty) {
      if (host.trim().toLowerCase() != targetHost.trim().toLowerCase()) {
        return false;
      }
    }

    final effectivePrimary = primaryPin ?? EnvConfig.sslPinPrimary;
    final effectiveBackup = backupPin ?? EnvConfig.sslPinBackup;

    final validPins = <String>{
      if (effectivePrimary != null && effectivePrimary.isNotEmpty)
        _normalizePin(effectivePrimary),
      if (effectiveBackup != null && effectiveBackup.isNotEmpty)
        _normalizePin(effectiveBackup),
    };

    // 4. Fail-closed: Jika tidak ada pin yang dikonfigurasi di environment
    // non-dev, tolak sertifikat yang gagal divalidasi oleh OS ini
    if (validPins.isEmpty) {
      return false;
    }

    final certDer = cert.der;

    // 5. Verifikasi hash SPKI SHA-256 (prioritas utama standar industri)
    final spkiBytes = extractSpkiDer(certDer);
    if (spkiBytes != null) {
      final spkiPin = _computePin(spkiBytes);
      if (validPins.contains(spkiPin)) {
        return true;
      }
    }

    // 6. Fallback verifikasi hash Sertifikat DER utuh (hanya jika SPKI gagal)
    final certPin = _computePin(certDer);
    if (validPins.contains(certPin)) {
      return true;
    }

    return false;
  }

  /// Menormalisasi format string pin (misal "sha256/XXXX=" menjadi "XXXX=").
  static String _normalizePin(String rawPin) {
    final trimmed = rawPin.trim();
    if (trimmed.startsWith(_pinPrefix)) {
      return trimmed.substring(_pinPrefix.length);
    }
    return trimmed;
  }

  /// Menghitung base64-encoded SHA-256 digest dari byte array.
  static String _computePin(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Mengekstrak slice DER bytes dari `SubjectPublicKeyInfo` (SPKI) di dalam
  /// X.509 Certificate (RFC 5280).
  ///
  /// Menerapkan strict fail-fast parser: mengembalikan `null` jika ada field
  /// wajib yang hilang, urutan tag ASN.1 tidak valid, atau struktur malformed.
  static Uint8List? extractSpkiDer(List<int> certDer) {
    try {
      var offset = 0;

      // 1. Root Certificate SEQUENCE
      if (offset >= certDer.length || certDer[offset] != _asn1Sequence) {
        return null;
      }
      offset++;
      final rootDer = _readDerLength(certDer, offset);
      if (rootDer == null) return null;
      if (rootDer.contentOffset + rootDer.length > certDer.length) {
        return null;
      }
      offset = rootDer.contentOffset;

      // 2. TBSCertificate SEQUENCE
      if (offset >= certDer.length || certDer[offset] != _asn1Sequence) {
        return null;
      }
      offset++;
      final tbsDer = _readDerLength(certDer, offset);
      if (tbsDer == null) return null;
      offset = tbsDer.contentOffset;
      final tbsEnd = offset + tbsDer.length;

      if (tbsEnd > certDer.length) return null;

      // Elemen di dalam TBSCertificate (RFC 5280 Section 4.1):
      // Field 0: Version [0] EXPLICIT (opsional)
      if (offset < tbsEnd && certDer[offset] == _asn1VersionContextTag) {
        offset++;
        final verDer = _readDerLength(certDer, offset);
        if (verDer == null) return null;
        offset = verDer.contentOffset + verDer.length;
        if (offset > tbsEnd) return null;
      }

      // Field 1: SerialNumber (INTEGER) - Wajib
      if (offset >= tbsEnd || certDer[offset] != _asn1Integer) return null;
      offset++;
      final serialDer = _readDerLength(certDer, offset);
      if (serialDer == null) return null;
      offset = serialDer.contentOffset + serialDer.length;
      if (offset > tbsEnd) return null;

      // Field 2: Signature Algorithm (SEQUENCE) - Wajib
      if (offset >= tbsEnd || certDer[offset] != _asn1Sequence) return null;
      offset++;
      final sigDer = _readDerLength(certDer, offset);
      if (sigDer == null) return null;
      offset = sigDer.contentOffset + sigDer.length;
      if (offset > tbsEnd) return null;

      // Field 3: Issuer (SEQUENCE) - Wajib
      if (offset >= tbsEnd || certDer[offset] != _asn1Sequence) return null;
      offset++;
      final issuerDer = _readDerLength(certDer, offset);
      if (issuerDer == null) return null;
      offset = issuerDer.contentOffset + issuerDer.length;
      if (offset > tbsEnd) return null;

      // Field 4: Validity (SEQUENCE) - Wajib
      if (offset >= tbsEnd || certDer[offset] != _asn1Sequence) return null;
      offset++;
      final validityDer = _readDerLength(certDer, offset);
      if (validityDer == null) return null;
      offset = validityDer.contentOffset + validityDer.length;
      if (offset > tbsEnd) return null;

      // Field 5: Subject (SEQUENCE) - Wajib
      if (offset >= tbsEnd || certDer[offset] != _asn1Sequence) return null;
      offset++;
      final subjectDer = _readDerLength(certDer, offset);
      if (subjectDer == null) return null;
      offset = subjectDer.contentOffset + subjectDer.length;
      if (offset > tbsEnd) return null;

      // Field 6: SubjectPublicKeyInfo (SEQUENCE) - Wajib
      if (offset >= tbsEnd || certDer[offset] != _asn1Sequence) return null;
      final spkiStart = offset;
      offset++;
      final spkiDer = _readDerLength(certDer, offset);
      if (spkiDer == null) return null;
      final totalSpkiLen = (spkiDer.contentOffset - spkiStart) + spkiDer.length;

      if (spkiStart + totalSpkiLen > tbsEnd ||
          spkiStart + totalSpkiLen > certDer.length) {
        return null;
      }

      return Uint8List.fromList(
        certDer.sublist(spkiStart, spkiStart + totalSpkiLen),
      );
    } on Object catch (_) {
      return null;
    }
  }

  /// Membaca header panjang DER pada [offset].
  ///
  /// Mengembalikan record `({int length, int contentOffset})` atau `null` jika
  /// format panjang malformed, indefinite form (0x80), atau melampaui buffer.
  static ({int length, int contentOffset})? _readDerLength(
    List<int> bytes,
    int offset,
  ) {
    if (offset >= bytes.length) return null;
    final first = bytes[offset];
    if ((first & 0x80) == 0) {
      return (length: first, contentOffset: offset + 1);
    }
    final numBytes = first & 0x7f;
    if (numBytes == 0 ||
        numBytes > 4 ||
        offset + 1 + numBytes > bytes.length ||
        (numBytes > 1 && bytes[offset + 1] == 0)) {
      return null;
    }
    var length = 0;
    for (var i = 0; i < numBytes; i++) {
      length = (length << 8) | bytes[offset + 1 + i];
    }
    if (length < 0) return null;
    return (length: length, contentOffset: offset + 1 + numBytes);
  }

  static String? _resolveDefaultApiHost() {
    final rawUrl = EnvConfig.apiBaseUrl;
    if (rawUrl.isEmpty) return null;
    return Uri.tryParse(rawUrl)?.host;
  }
}
