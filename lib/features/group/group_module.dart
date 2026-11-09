import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/group/data/datasources/group_remote_data_source.dart';
import 'package:kawalo_mobile/features/group/data/repositories/group_repository_impl.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';

/// Feature Composition Root untuk modul grup.
///
/// Menyediakan factory method untuk instansiasi datasource dan repositori
/// secara modular tanpa perakitan manual berulang.
class GroupModule {
  /// Membuat instance [GroupRepository].
  static GroupRepository createRepository({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) {
    final remoteDataSource = GroupRemoteDataSourceImpl(apiClient: apiClient);
    return GroupRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
  }
}
