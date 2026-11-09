import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheWipeable extends Mock implements CacheWipeable {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSyncStorageService extends Mock implements SyncStorageService {}

void main() {
  group('CacheWiper Unit Tests', () {
    late MockCacheWipeable mockWipeable1;
    late MockCacheWipeable mockWipeable2;
    late MockSyncStorageService mockSyncStorage;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockWipeable1 = MockCacheWipeable();
      mockWipeable2 = MockCacheWipeable();
      mockSyncStorage = MockSyncStorageService();
      mockSecureStorage = MockSecureStorageService();
    });

    test('wipeAll executes clearCache on all registered wipeables and sync '
        'storage', () async {
      when(() => mockWipeable1.clearCache()).thenAnswer((_) async {});
      when(() => mockWipeable2.clearCache()).thenAnswer((_) async {});
      when(() => mockSyncStorage.clearAll()).thenAnswer((_) async {});

      final wiper = CacheWiper(
        wipeables: [mockWipeable1, mockWipeable2],
        syncStorageService: mockSyncStorage,
      );

      await wiper.wipeAll();

      verify(() => mockWipeable1.clearCache()).called(1);
      verify(() => mockWipeable2.clearCache()).called(1);
      verify(() => mockSyncStorage.clearAll()).called(1);
    });

    test('wipeAll delegates to secureStorageService when syncStorageService is '
        'null', () async {
      when(() => mockWipeable1.clearCache()).thenAnswer((_) async {});
      when(
        () => mockSecureStorage.clearAllSyncTimestamps(),
      ).thenAnswer((_) async {});

      final wiper = CacheWiper(
        wipeables: [mockWipeable1],
        secureStorageService: mockSecureStorage,
      );

      await wiper.wipeAll();

      verify(() => mockWipeable1.clearCache()).called(1);
      verify(() => mockSecureStorage.clearAllSyncTimestamps()).called(1);
    });

    test(
      'wipeAll is resilient (best-effort) when one wipeable throws exception',
      () async {
        when(
          () => mockWipeable1.clearCache(),
        ).thenThrow(Exception('Disk I/O error'));
        when(() => mockWipeable2.clearCache()).thenAnswer((_) async {});
        when(() => mockSyncStorage.clearAll()).thenAnswer((_) async {});

        final wiper = CacheWiper(
          wipeables: [mockWipeable1, mockWipeable2],
          syncStorageService: mockSyncStorage,
        );

        // Should not throw
        await wiper.wipeAll();

        verify(() => mockWipeable1.clearCache()).called(1);
        verify(() => mockWipeable2.clearCache()).called(1);
        verify(() => mockSyncStorage.clearAll()).called(1);
      },
    );

    test('register dynamically adds new CacheWipeable instance', () {
      final wiper = CacheWiper();
      expect(wiper.wipeables, isEmpty);

      wiper.register(mockWipeable1);
      expect(wiper.wipeables, [mockWipeable1]);
    });
  });
}
