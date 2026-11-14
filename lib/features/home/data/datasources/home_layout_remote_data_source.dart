import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/home/data/models/home_layout_model.dart';

abstract interface class HomeLayoutRemoteDataSource {
  Future<HomeLayoutModel> get();

  Future<HomeLayoutModel> put(HomeLayoutModel layout);
}

class HomeLayoutRemoteDataSourceImpl implements HomeLayoutRemoteDataSource {
  const HomeLayoutRemoteDataSourceImpl({required this.apiClient});

  static const _path = '/v1/me/home-layout';

  final ApiClient apiClient;

  @override
  Future<HomeLayoutModel> get() async => _data(await apiClient.get(_path));

  @override
  Future<HomeLayoutModel> put(HomeLayoutModel layout) async =>
      _data(await apiClient.put(_path, body: layout.toJson()));

  static HomeLayoutModel _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic>
        ? HomeLayoutModel.fromJson(data)
        : const HomeLayoutModel();
  }
}
