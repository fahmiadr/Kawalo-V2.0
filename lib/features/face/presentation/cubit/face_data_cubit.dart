import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';

class FaceDataState extends Equatable {
  const FaceDataState({
    this.status,
    this.loading = false,
    this.deleting = false,
    this.error,
    this.deleted = false,
  });

  final FaceStatus? status;
  final bool loading;
  final bool deleting;
  final String? error;

  /// Set once by a successful delete, for the confirmation snackbar.
  final bool deleted;

  @override
  List<Object?> get props => [status, loading, deleting, error, deleted];
}

/// "Pengaturan > Data Wajah": shows the registration and deletes it on request.
class FaceDataCubit extends Cubit<FaceDataState> {
  FaceDataCubit({required this.repository}) : super(const FaceDataState());

  final FaceRepository repository;

  Future<void> load() async {
    emit(FaceDataState(status: state.status, loading: true));
    final result = await repository.getStatus();
    if (isClosed) return;
    emit(
      result.match(
        (f) => FaceDataState(status: state.status, error: f.message),
        (status) => FaceDataState(status: status),
      ),
    );
  }

  Future<void> delete() async {
    emit(FaceDataState(status: state.status, deleting: true));
    final result = await repository.deleteMine();
    if (isClosed) return;
    await result.match(
      (f) async => emit(FaceDataState(status: state.status, error: f.message)),
      (_) async {
        emit(FaceDataState(status: state.status, deleted: true));
        await load();
      },
    );
  }
}
