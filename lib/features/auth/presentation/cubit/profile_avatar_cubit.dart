import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';

sealed class ProfileAvatarState extends Equatable {
  const ProfileAvatarState();

  @override
  List<Object?> get props => [];
}

class ProfileAvatarIdle extends ProfileAvatarState {
  const ProfileAvatarIdle();
}

class ProfileAvatarBusy extends ProfileAvatarState {
  const ProfileAvatarBusy();
}

class ProfileAvatarSuccess extends ProfileAvatarState {
  const ProfileAvatarSuccess({required this.avatarUrl, required this.message});

  /// `null` after the photo was removed.
  final String? avatarUrl;
  final String message;

  @override
  List<Object?> get props => [avatarUrl, message];
}

class ProfileAvatarFailure extends ProfileAvatarState {
  const ProfileAvatarFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Uploads a new profile photo (compressed by [UploadRepository]) and saves its
/// URL on the account. Whoever listens applies the result to the session.
class ProfileAvatarCubit extends Cubit<ProfileAvatarState> {
  ProfileAvatarCubit({
    required AuthRepository authRepository,
    required UploadRepository uploadRepository,
  }) : _auth = authRepository,
       _upload = uploadRepository,
       super(const ProfileAvatarIdle());

  final AuthRepository _auth;
  final UploadRepository _upload;

  Future<void> setPhoto(AppMediaFile file) async {
    if (state is ProfileAvatarBusy) return;
    emit(const ProfileAvatarBusy());
    final uploaded = await _upload.uploadImage(file);
    if (isClosed) return;
    await uploaded.fold(
      (failure) async => emit(ProfileAvatarFailure(failure.message)),
      (url) => _save(url, 'Foto profil berhasil diperbarui.'),
    );
  }

  Future<void> removePhoto() async {
    if (state is ProfileAvatarBusy) return;
    emit(const ProfileAvatarBusy());
    await _save(null, 'Foto profil dihapus.');
  }

  Future<void> _save(String? url, String successMessage) async {
    final saved = await _auth.updateAvatar(url);
    if (isClosed) return;
    emit(
      saved.fold(
        (failure) => ProfileAvatarFailure(failure.message),
        (savedUrl) =>
            ProfileAvatarSuccess(avatarUrl: savedUrl, message: successMessage),
      ),
    );
  }
}
