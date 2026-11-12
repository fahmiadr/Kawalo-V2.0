import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/profile_avatar_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUploadRepository extends Mock implements UploadRepository {}

void main() {
  const file = AppMediaFile(name: 'foto.jpg', path: '/tmp/foto.jpg');
  late _MockAuthRepository auth;
  late _MockUploadRepository upload;

  setUpAll(() => registerFallbackValue(file));

  setUp(() {
    auth = _MockAuthRepository();
    upload = _MockUploadRepository();
  });

  ProfileAvatarCubit build() =>
      ProfileAvatarCubit(authRepository: auth, uploadRepository: upload);

  blocTest<ProfileAvatarCubit, ProfileAvatarState>(
    'uploads the compressed image, then saves its URL on the account',
    build: build,
    setUp: () {
      when(
        () => upload.uploadImage(any()),
      ).thenAnswer((_) async => const Right('https://x/u/a.webp'));
      when(
        () => auth.updateAvatar('https://x/u/a.webp'),
      ).thenAnswer((_) async => const Right('https://x/u/a.webp'));
    },
    act: (cubit) => cubit.setPhoto(file),
    expect: () => const [
      ProfileAvatarBusy(),
      ProfileAvatarSuccess(
        avatarUrl: 'https://x/u/a.webp',
        message: 'Foto profil berhasil diperbarui.',
      ),
    ],
    verify: (_) {
      verify(() => upload.uploadImage(file)).called(1);
      verify(() => auth.updateAvatar('https://x/u/a.webp')).called(1);
    },
  );

  blocTest<ProfileAvatarCubit, ProfileAvatarState>(
    'a failed upload never reaches the API',
    build: build,
    setUp: () => when(
      () => upload.uploadImage(any()),
    ).thenAnswer((_) async => const Left(NoInternetFailure())),
    act: (cubit) => cubit.setPhoto(file),
    expect: () => [
      const ProfileAvatarBusy(),
      const ProfileAvatarFailure(
        'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
      ),
    ],
    verify: (_) => verifyNever(() => auth.updateAvatar(any())),
  );

  blocTest<ProfileAvatarCubit, ProfileAvatarState>(
    'an API error (invalid URL) is reported as a failure',
    build: build,
    setUp: () {
      when(
        () => upload.uploadImage(any()),
      ).thenAnswer((_) async => const Right('bad'));
      when(
        () => auth.updateAvatar(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('URL tidak valid.')));
    },
    act: (cubit) => cubit.setPhoto(file),
    expect: () => const [
      ProfileAvatarBusy(),
      ProfileAvatarFailure('URL tidak valid.'),
    ],
  );

  blocTest<ProfileAvatarCubit, ProfileAvatarState>(
    'removePhoto sends null without uploading',
    build: build,
    setUp: () => when(
      () => auth.updateAvatar(null),
    ).thenAnswer((_) async => const Right(null)),
    act: (cubit) => cubit.removePhoto(),
    expect: () => const [
      ProfileAvatarBusy(),
      ProfileAvatarSuccess(avatarUrl: null, message: 'Foto profil dihapus.'),
    ],
    verify: (_) => verifyNever(() => upload.uploadImage(any())),
  );
}
