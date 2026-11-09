import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/group/group_module.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockApiClient mockApiClient;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockApiClient = MockApiClient();
    mockNetworkInfo = MockNetworkInfo();
  });

  group('GroupModule Tests', () {
    test('createRepository creates GroupRepository instance correctly', () {
      final repository = GroupModule.createRepository(
        apiClient: mockApiClient,
        networkInfo: mockNetworkInfo,
      );

      expect(repository, isNotNull);
    });
  });
}
