import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                storageNamespace: 'kawalo_secure_storage',
              ),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'JWT_ACCESS_TOKEN';
  static const String _refreshTokenKey = 'JWT_REFRESH_TOKEN';
  static const String _userDataKey = 'USER_DATA';
  static const String _sessionDataKey = 'AUTH_SESSION_DATA';
  static const String _onboardingCompletedKey = 'ONBOARDING_COMPLETED';
  static const String _jwksCacheKey = 'JWKS_CACHE';
  static const String _lastEmailKey = 'LAST_LOGGED_IN_EMAIL';

  Future<void> saveJwksCache(String jwksJson) async {
    await _storage.write(key: _jwksCacheKey, value: jwksJson);
  }

  Future<String?> getJwksCache() => _storage.read(key: _jwksCacheKey);

  Future<void> clearJwksCache() => _storage.delete(key: _jwksCacheKey);

  Future<void> saveLastEmail(String email) async {
    await _storage.write(key: _lastEmailKey, value: email.trim());
  }

  Future<String?> getLastEmail() => _storage.read(key: _lastEmailKey);

  Future<void> clearLastEmail() => _storage.delete(key: _lastEmailKey);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  Future<String?> getUserData() => _storage.read(key: _userDataKey);

  Future<void> saveAuthSession(String sessionData) async {
    await _storage.write(key: _sessionDataKey, value: sessionData);
  }

  Future<String?> getAuthSession() => _storage.read(key: _sessionDataKey);

  /// Menyimpan status penyelesaian onboarding pengguna setelah berhasil
  /// melakukan login pertama kalinya.
  Future<void> setOnboardingCompleted({bool completed = true}) async {
    await _storage.write(
      key: _onboardingCompletedKey,
      value: completed.toString(),
    );
  }

  /// Memeriksa apakah pengguna telah menyelesaikan onboarding
  /// (dan login pertama).
  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _onboardingCompletedKey);
    return value?.toLowerCase() == 'true';
  }

  /// Membersihkan sesi autentikasi pengguna.
  ///
  /// Parameter [preserveEmail] (default: `true`) mempertahankan
  /// [_lastEmailKey] saat sesi kedaluwarsa secara otomatis/diam-diam,
  /// sehingga memudahkan pengguna saat login ulang.
  /// Bila pengguna melakukan logout secara sengaja, set ke `false` agar
  /// email tersimpan ikut dibersihkan.
  Future<void> clearAuthSession({bool preserveEmail = true}) async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _sessionDataKey);
    if (!preserveEmail) {
      await _storage.delete(key: _lastEmailKey);
    }
  }

  static const String _syncPrefix = 'LAST_SYNC_';

  /// Menyimpan waktu terakhir data fitur berhasil disinkronkan dengan server.
  Future<void> saveLastSync(String featureKey, DateTime timestamp) async {
    await _storage.write(
      key: '$_syncPrefix$featureKey',
      value: timestamp.toIso8601String(),
    );
  }

  /// Mengambil waktu terakhir data fitur berhasil disinkronkan dengan server.
  Future<DateTime?> getLastSync(String featureKey) async {
    final value = await _storage.read(key: '$_syncPrefix$featureKey');
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Menghapus rekaman waktu sinkronisasi fitur tertentu.
  Future<void> clearLastSync(String featureKey) async {
    await _storage.delete(key: '$_syncPrefix$featureKey');
  }

  /// Menghapus seluruh rekaman waktu sinkronisasi fitur
  /// (kunci berawalan `LAST_SYNC_`).
  Future<void> clearAllSyncTimestamps() async {
    final allEntries = await _storage.readAll();
    for (final key in allEntries.keys) {
      if (key.startsWith(_syncPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }

  /// Menghapus seluruh data di secure storage termasuk status onboarding.
  Future<void> clearAll() => _storage.deleteAll();
}
