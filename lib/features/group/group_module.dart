import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/group/data/datasources/group_remote_data_source.dart';
import 'package:kawalo_mobile/features/group/data/repositories/group_repository_impl.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';

/// Feature Composition Root untuk modul grup.
///
/// Menyediakan factory method untuk instansiasi datasource, repositori,
/// dan usecase secara modular tanpa perakitan manual berulang.
class GroupModule {
  /// Membuat instance [GroupRepository].
  static GroupRepository createRepository({
    required ApiClient apiClient,
    NetworkInfo? networkInfo,
  }) {
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GroupRemoteDataSourceImpl(apiClient: apiClient);
    return GroupRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: effectiveNetworkInfo,
    );
  }

  /// Membuat instance [GetGroupMembersUseCase] langsung dari [ApiClient].
  static GetGroupMembersUseCase createGetGroupMembersUseCase({
    required ApiClient apiClient,
    NetworkInfo? networkInfo,
  }) {
    final repository = createRepository(
      apiClient: apiClient,
      networkInfo: networkInfo,
    );
    return GetGroupMembersUseCase(repository);
  }
}
