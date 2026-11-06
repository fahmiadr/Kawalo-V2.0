import 'dart:convert';

/// Helper murni Dart untuk mengonversi RFC 7517 RSA JSON Web Key (JWK)
/// menjadi format SubjectPublicKeyInfo (SPKI) PEM berbasis ASN.1 DER.
///
/// Digunakan untuk memvalidasi token JWT dengan kunci
/// publik yang diperoleh secara dinamis dari endpoint JWKS tanpa membutuhkan
/// dependensi eksternal tambahan.
class RsaJwkHelper {
  RsaJwkHelper._();

  /// Mengonversi map [jwk] (yang berisi parameter `n` dan `e`) menjadi
  /// string Public Key PEM standar X.509 SubjectPublicKeyInfo (SPKI).
  ///
  /// Melempar [FormatException] bila [jwk] tidak memiliki properti yang valid.
  static String rsaJwkToPem(Map<String, dynamic> jwk) {
    final kty = jwk['kty'] as String?;
    if (kty != null && kty != 'RSA') {
      throw FormatException('Unsupported key type (kty): $kty. Expected RSA.');
    }

    final nStr = jwk['n'] as String?;
    final eStr = jwk['e'] as String?;

    if (nStr == null || nStr.trim().isEmpty) {
      throw const FormatException('JWK missing required modulus (n)');
    }
    if (eStr == null || eStr.trim().isEmpty) {
      throw const FormatException('JWK missing required exponent (e)');
    }

    final modulusBytes = base64Url.decode(base64Url.normalize(nStr.trim()));
    final exponentBytes = base64Url.decode(base64Url.normalize(eStr.trim()));

    // 1. Encode ASN.1 DER integers untuk modulus (n) dan public exponent (e)
    final modDer = _encodeDerInteger(modulusBytes);
    final expDer = _encodeDerInteger(exponentBytes);

    // 2. Wrap ke dalam PKCS#1 RSAPublicKey SEQUENCE
    final pkcs1Content = <int>[...modDer, ...expDer];
    final pkcs1Der = <int>[
      0x30,
      ..._encodeDerLength(pkcs1Content.length),
      ...pkcs1Content,
    ];

    // 3. Wrap PKCS#1 DER ke dalam BIT STRING (dengan 0 unused bits)
    final bitStringContent = <int>[0x00, ...pkcs1Der];
    final bitStringDer = <int>[
      0x03,
      ..._encodeDerLength(bitStringContent.length),
      ...bitStringContent,
    ];

    // 4. AlgorithmIdentifier untuk rsaEncryption (OID: 1.2.840.113549.1.1.1)
    // SEQUENCE { OBJECT IDENTIFIER rsaEncryption, NULL }
    const rsaAlgorithmIdentifier = <int>[
      0x30, 0x0d, // SEQUENCE, 13 bytes
      0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, // OID
      0x05, 0x00, // NULL
    ];

    // 5. SubjectPublicKeyInfo (SPKI) SEQUENCE
    final spkiContent = <int>[...rsaAlgorithmIdentifier, ...bitStringDer];
    final spkiDer = <int>[
      0x30,
      ..._encodeDerLength(spkiContent.length),
      ...spkiContent,
    ];

    // 6. Base64 encoding dan format PEM dengan wrapping baris 64 karakter
    final base64Spki = base64.encode(spkiDer);
    final buffer = StringBuffer('-----BEGIN PUBLIC KEY-----\n');
    for (var i = 0; i < base64Spki.length; i += 64) {
      final end = (i + 64 > base64Spki.length) ? base64Spki.length : i + 64;
      buffer.writeln(base64Spki.substring(i, end));
    }
    buffer.writeln('-----END PUBLIC KEY-----');

    return buffer.toString();
  }

  /// Melakukan enkoding ASN.1 DER length.
  static List<int> _encodeDerLength(int length) {
    if (length < 128) {
      return [length];
    } else if (length < 256) {
      return [0x81, length];
    } else if (length < 65536) {
      return [0x82, (length >> 8) & 0xff, length & 0xff];
    } else if (length < 16777216) {
      return [
        0x83,
        (length >> 16) & 0xff,
        (length >> 8) & 0xff,
        length & 0xff,
      ];
    } else {
      return [
        0x84,
        (length >> 24) & 0xff,
        (length >> 16) & 0xff,
        (length >> 8) & 0xff,
        length & 0xff,
      ];
    }
  }

  /// Melakukan enkoding integer ke format ASN.1 DER dengan penanganan
  /// sign-bit (MSB 0x80) dan pembersihan leading zeros.
  static List<int> _encodeDerInteger(List<int> bytes) {
    var start = 0;
    while (start < bytes.length - 1 && bytes[start] == 0) {
      start++;
    }
    final trimmed = bytes.sublist(start);
    final result = <int>[];

    if (trimmed.isEmpty) {
      result.add(0x00);
    } else {
      // Jika bit paling signifikan (MSB) bernilai 1, tambahkan prefix 0x00
      // agar tidak dianggap sebagai bilangan negatif dalam representasi
      // two's complement.
      if ((trimmed[0] & 0x80) != 0) {
        result.add(0x00);
      }
      result.addAll(trimmed);
    }

    return [0x02, ..._encodeDerLength(result.length), ...result];
  }
}
