import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/bootstrap.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/attendance/attendance_module.dart';
import 'package:kawalo_mobile/features/guest/guest_module.dart';
import 'package:kawalo_mobile/features/information/information_module.dart';
import 'package:kawalo_mobile/features/operational/operational_module.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockIsar extends Mock implements Isar {}

void main() {
  test(
    'every Isar schema has a wipeable module that clears its collection',
    () {
      final apiClient = MockApiClient();
      final isar = MockIsar();
      final networkInfo = MockNetworkInfo();
      final syncStorage = SyncStorageService();

      // Keep in sync with the module list in `main.dart`.
      final modules = <CacheWipeableModule>[
        GuestModule(
          apiClient: apiClient,
          isar: isar,
          networkInfo: networkInfo,
          syncStorageService: syncStorage,
        ),
        InformationModule(
          apiClient: apiClient,
          isar: isar,
          networkInfo: networkInfo,
          syncStorageService: syncStorage,
        ),
        AttendanceModule(
          apiClient: apiClient,
          isar: isar,
          networkInfo: networkInfo,
          syncStorageService: syncStorage,
        ),
        OperationalModule(
          apiClient: apiClient,
          isar: isar,
          networkInfo: networkInfo,
          syncStorageService: syncStorage,
        ),
      ];

      final wiped = [for (final m in modules) m.cacheWipeable.collectionName];
      final schemas = [for (final s in isarSchemas) s.name];

      expect(wiped, unorderedEquals(schemas));
      expect(wiped.toSet().length, wiped.length, reason: 'duplicate wipeable');
    },
  );
}
