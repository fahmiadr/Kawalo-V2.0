import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/home/data/datasources/home_layout_remote_data_source.dart';
import 'package:kawalo_mobile/features/home/data/repositories/home_layout_repository_impl.dart';
import 'package:kawalo_mobile/features/home/domain/repositories/home_layout_repository.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_layout_cubit.dart';

/// Composition root of the Beranda. The layout cache is a per-user preference
/// in secure storage, not an Isar collection, so it is not wiped on logout.
final class HomeModule {
  HomeModule({
    required ApiClient apiClient,
    required SecureStorageService storage,
  }) : layoutRepository = HomeLayoutRepositoryImpl(
         remoteDataSource: HomeLayoutRemoteDataSourceImpl(apiClient: apiClient),
         storage: storage,
       );

  final HomeLayoutRepository layoutRepository;

  HomeLayoutCubit createLayoutCubit() =>
      HomeLayoutCubit(repository: layoutRepository);
}
