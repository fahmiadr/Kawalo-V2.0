import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kawalo_mobile/core/storage/native_token_store.dart';

/// With [nativeTokens] (Android) the access/refresh pair lives in the native
/// vault, everything else stays in flutter_secure_storage.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
    NativeTokenStore? nativeTokens,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(
               storageNamespace: 'kawalo_secure_storage',
             ),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock,
             ),
           ),
       _nativeTokens = nativeTokens;
  final FlutterSecureStorage _storage;
  final NativeTokenStore? _nativeTokens;
  bool _nativeFailed = false;
  Future<NativeTokenStore?>? _nativeReady;

  /// Null on iOS, in tests, and for the rest of the run when the native vault
  /// failed (tokens then stay in flutter_secure_storage, as before 13 Nov
  /// 2026). Settled by the first token read, which every refresh follows.
  NativeTokenStore? get nativeTokens => _nativeFailed ? null : _nativeTokens;

  Future<NativeTokenStore?> _native() => _nativeReady ??= _adoptLegacyTokens();

  /// Builds before 13 Nov 2026 kept the pair in flutter_secure_storage. It is
  /// moved into the vault once, so updating the app does not log anyone out.
  Future<NativeTokenStore?> _adoptLegacyTokens() async {
    final native = _nativeTokens;
    if (native == null) return null;
    try {
      final current = await native.read();
      final legacyAccess = await _storage.read(key: _accessTokenKey);
      final legacyRefresh = await _storage.read(key: _refreshTokenKey);
      if (legacyAccess == null && legacyRefresh == null) return native;
      if (current.accessToken == null && current.refreshToken == null) {
        await native.save(
          accessToken: legacyAccess,
          refreshToken: legacyRefresh,
        );
      }
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      return native;
    } on Object catch (_) {
      _nativeFailed = true;
      return null;
    }
  }

  static const String _accessTokenKey = 'JWT_ACCESS_TOKEN';
  static const String _refreshTokenKey = 'JWT_REFRESH_TOKEN';
  static const String _userDataKey = 'USER_DATA';
  static const String _sessionDataKey = 'AUTH_SESSION_DATA';
  static const String _onboardingCompletedKey = 'ONBOARDING_COMPLETED';
  static const String _jwksCacheKey = 'JWKS_CACHE';
  static const String _lastEmailKey = 'LAST_LOGGED_IN_EMAIL';
  static const String _themeModeKey = 'THEME_MODE';

  Future<void> saveJwksCache(String jwksJson) async {
    await _storage.write(key: _jwksCacheKey, value: jwksJson);
  }

  Future<String?> getJwksCache() => _storage.read(key: _jwksCacheKey);

  Future<void> clearJwksCache() => _storage.delete(key: _jwksCacheKey);

  /// Device preference, not session data: [clearAuthSession] must not touch it.
  Future<void> saveThemeMode(String mode) =>
      _storage.write(key: _themeModeKey, value: mode);

  Future<String?> getThemeMode() => _storage.read(key: _themeModeKey);

  // Per user and group (see `HomeLayoutRepositoryImpl`); a preference, not
  // session data, so logout keeps it like the theme mode.
  static const String _homeLayoutPrefix = 'HOME_LAYOUT_';

  Future<void> saveHomeLayout(String scope, String json) =>
      _storage.write(key: '$_homeLayoutPrefix$scope', value: json);

  Future<String?> getHomeLayout(String scope) =>
      _storage.read(key: '$_homeLayoutPrefix$scope');

  Future<void> saveLastEmail(String email) async {
    await _storage.write(key: _lastEmailKey, value: email.trim());
  }

  Future<String?> getLastEmail() => _storage.read(key: _lastEmailKey);

  Future<void> clearLastEmail() => _storage.delete(key: _lastEmailKey);

  Future<void> saveAccessToken(String token) async {
    final native = await _native();
    if (native != null) return await native.save(accessToken: token);
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    final native = await _native();
    if (native != null) return (await native.read()).accessToken;
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    final native = await _native();
    if (native != null) return await native.save(refreshToken: token);
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    final native = await _native();
    if (native != null) return (await native.read()).refreshToken;
    return await _storage.read(key: _refreshTokenKey);
  }

  /// One write for the pair, so a refresh by the PTT service cannot land
  /// between the two halves of a login or group switch.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final native = await _native();
    if (native != null) {
      return await native.save(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

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
    await _clearNativeTokens();
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
  Future<void> clearAll() async {
    await _clearNativeTokens();
    await _storage.deleteAll();
  }

  // Attempted even after a vault failure: a stale pair there would let the
  // PTT service keep a logged-out session alive.
  Future<void> _clearNativeTokens() async {
    try {
      await _nativeTokens?.clear();
    } on Object catch (_) {}
  }
}
