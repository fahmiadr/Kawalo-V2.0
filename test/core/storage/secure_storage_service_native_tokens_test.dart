import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/storage/native_token_store.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeNativeTokenStore implements NativeTokenStore {
  String? accessToken;
  String? refreshToken;
  bool fail = false;
  int saves = 0;

  @override
  Future<void> Function()? onSessionEnded;

  @override
  Future<({String? accessToken, String? refreshToken})> read() async {
    if (fail) throw Exception('keystore');
    return (accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> save({String? accessToken, String? refreshToken}) async {
    saves++;
    this.accessToken = accessToken ?? this.accessToken;
    this.refreshToken = refreshToken ?? this.refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<void> configure(String baseUrl) async {}

  @override
  Future<NativeRefreshResult> refresh({String? staleAccessToken}) =>
      throw UnimplementedError();
}

void main() {
  late MockFlutterSecureStorage legacy;
  late FakeNativeTokenStore native;
  late Map<String, String> legacyValues;

  setUp(() {
    legacy = MockFlutterSecureStorage();
    native = FakeNativeTokenStore();
    legacyValues = {};
    when(() => legacy.read(key: any(named: 'key'))).thenAnswer(
      (call) async => legacyValues[call.namedArguments[#key] as String],
    );
    when(() => legacy.delete(key: any(named: 'key'))).thenAnswer((call) async {
      legacyValues.remove(call.namedArguments[#key] as String);
    });
    when(
      () => legacy.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      legacyValues[call.namedArguments[#key] as String] =
          call.namedArguments[#value] as String;
    });
  });

  SecureStorageService service() =>
      SecureStorageService(storage: legacy, nativeTokens: native);

  test('an update moves the old pair into the vault without logout', () async {
    legacyValues['JWT_ACCESS_TOKEN'] = 'old-access';
    legacyValues['JWT_REFRESH_TOKEN'] = 'old-refresh';
    final storage = service();

    expect(await storage.getAccessToken(), 'old-access');
    expect(await storage.getRefreshToken(), 'old-refresh');
    expect(native.refreshToken, 'old-refresh');
    expect(legacyValues, isEmpty);
    expect(native.saves, 1);
  });

  test('a pair already in the vault is not overwritten by leftovers', () async {
    native
      ..accessToken = 'vault-access'
      ..refreshToken = 'vault-refresh';
    legacyValues['JWT_REFRESH_TOKEN'] = 'leftover';

    expect(await service().getRefreshToken(), 'vault-refresh');
    expect(native.saves, 0);
    expect(legacyValues, isEmpty);
  });

  test('saveTokens writes the pair once and clearAuthSession empties the '
      'vault', () async {
    final storage = service();
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    expect(native.saves, 1);
    expect(native.accessToken, 'a');

    await storage.clearAuthSession();
    expect(native.accessToken, isNull);
    expect(native.refreshToken, isNull);
  });

  test('a broken vault keeps this run on flutter_secure_storage', () async {
    native.fail = true;
    legacyValues['JWT_ACCESS_TOKEN'] = 'old-access';
    final storage = service();

    expect(await storage.getAccessToken(), 'old-access');
    expect(storage.nativeTokens, isNull);
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    expect(legacyValues['JWT_REFRESH_TOKEN'], 'r');
  });

  test('without a vault (iOS) nothing changes', () async {
    final storage = SecureStorageService(storage: legacy);
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');

    expect(storage.nativeTokens, isNull);
    expect(await storage.getAccessToken(), 'a');
  });
}
