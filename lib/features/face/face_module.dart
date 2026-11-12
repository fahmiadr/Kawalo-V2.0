import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/face/data/datasources/face_remote_data_source.dart';
import 'package:kawalo_mobile/features/face/data/repositories/face_repository_impl.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';

/// Composition root of the face feature. Online only (biometric data is never
/// cached on the device), so there is nothing to wipe on logout.
final class FaceModule {
  FaceModule({required ApiClient apiClient})
    : repository = FaceRepositoryImpl(
        remoteDataSource: FaceRemoteDataSource(apiClient: apiClient),
      );

  final FaceRepository repository;
}
