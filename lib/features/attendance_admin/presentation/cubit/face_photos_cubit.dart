import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';

enum FacePhotosPhase { loading, loaded, failure }

class FacePhotosState extends Equatable {
  const FacePhotosState({
    this.phase = FacePhotosPhase.loading,
    this.paths = const [],
    this.errorMessage,
  });

  final FacePhotosPhase phase;

  /// Local files of the registration photos that could be downloaded.
  final List<String> paths;
  final String? errorMessage;

  @override
  List<Object?> get props => [phase, paths, errorMessage];
}

/// Downloads a member's registration photos (admin only). The temporary files
/// are biometric data, so [close] deletes them.
class FacePhotosCubit extends Cubit<FacePhotosState> {
  FacePhotosCubit({required this.repository, required this.email})
    : super(const FacePhotosState());

  final AttendanceAdminRepository repository;
  final String email;

  final List<String> _downloaded = [];

  Future<void> load() async {
    emit(const FacePhotosState());
    final listed = await repository.getFacePhotos(email);
    if (isClosed) return;
    final photos = listed.getRight().toNullable();
    if (photos == null) {
      emit(
        FacePhotosState(
          phase: FacePhotosPhase.failure,
          errorMessage: listed.getLeft().toNullable()?.message,
        ),
      );
      return;
    }
    final results = await Future.wait(
      photos.map(
        (p) => repository.downloadFacePhoto(email: email, photoId: p.id),
      ),
    );
    final paths = results.map((r) => r.toNullable()).nonNulls.toList();
    _downloaded.addAll(paths);
    if (isClosed) {
      await _discardAll();
      return;
    }
    if (paths.isEmpty && photos.isNotEmpty) {
      emit(
        const FacePhotosState(
          phase: FacePhotosPhase.failure,
          errorMessage: 'Foto registrasi tidak dapat dimuat.',
        ),
      );
      return;
    }
    emit(FacePhotosState(phase: FacePhotosPhase.loaded, paths: paths));
  }

  Future<void> _discardAll() async {
    await Future.wait(_downloaded.map(repository.discardPhoto));
    _downloaded.clear();
  }

  @override
  Future<void> close() async {
    await _discardAll();
    await super.close();
  }
}
