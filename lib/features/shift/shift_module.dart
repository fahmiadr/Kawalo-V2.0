import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/shift/data/datasources/shift_remote_data_source.dart';
import 'package:kawalo_mobile/features/shift/data/repositories/shift_repository_impl.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_cubit.dart';

/// Composition root of shift management. Online-only, so unlike the cached
/// modules it has nothing to wipe on logout.
final class ShiftModule {
  ShiftModule({required ApiClient apiClient, required NetworkInfo networkInfo})
    : repository = ShiftRepositoryImpl(
        remoteDataSource: ShiftRemoteDataSourceImpl(apiClient: apiClient),
        networkInfo: networkInfo,
      );

  final ShiftRepository repository;

  ShiftListCubit createListCubit() => ShiftListCubit(repository: repository);

  /// Pass [initial] to edit an existing shift.
  ShiftFormCubit createFormCubit({ShiftEntity? initial}) =>
      ShiftFormCubit(repository: repository, initial: initial);
}
