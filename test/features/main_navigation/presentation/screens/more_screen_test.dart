import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/change_password_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/background_access_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/more_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUploadRepository extends Mock implements UploadRepository {}

class _MockBackgroundAccessService extends Mock
    implements BackgroundAccessService {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakePicker implements MediaPickerService {
  _FakePicker(this.gallery);

  final List<AppMediaFile> gallery;

  @override
  Future<List<AppMediaFile>> pickMultiImagesFromGallery({int? limit}) async =>
      gallery;

  @override
  Future<List<AppMediaFile>> captureMultiImagesFromCamera(
    BuildContext context, {
    int maxPhotos = 4,
    int alreadyAttachedCount = 0,
    bool allowSkip = false,
  }) async => const [];

  @override
  Future<AppMediaFile?> pickDocumentFile() async => null;
}

void main() {
  const file = AppMediaFile(name: 'foto.jpg', path: '/tmp/foto.jpg');
  const withoutPhoto = UserEntity(
    id: 'usr_1',
    email: 'zaki@kawalo.id',
    name: 'Ahmad Zaki',
    groups: [],
  );

  late _MockAuthRepository authRepository;
  late _MockUploadRepository uploadRepository;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AvatarUpdated(null));
    registerFallbackValue(file);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    uploadRepository = _MockUploadRepository();
    authBloc = _MockAuthBloc();
  });

  Future<void> pump(
    WidgetTester tester, {
    UserEntity user = withoutPhoto,
    MediaPickerService? picker,
    BackgroundAccessCubit Function()? createAccessCubit,
  }) async {
    when(() => authBloc.state).thenReturn(Authenticated(user: user));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<UploadRepository>.value(value: uploadRepository),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: Scaffold(
              body: MoreScreen(
                mediaPicker: picker,
                createBackgroundAccessCubit:
                    createAccessCubit ??
                    () => BackgroundAccessCubit(
                      service: _MockBackgroundAccessService(),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(AppUserAvatar));
    await tester.pumpAndSettle();
  }

  testWidgets('avatar is a 64 px circle with two initials', (tester) async {
    await pump(tester);

    final avatar = tester.widget<AppUserAvatar>(find.byType(AppUserAvatar));
    expect(avatar.size, 64);
    expect(avatar.circle, isTrue);
    expect(avatar.maxInitials, 2);
    expect(find.text('AZ'), findsOneWidget);
  });

  testWidgets('sheet offers camera and gallery, no delete without a photo', (
    tester,
  ) async {
    await pump(tester);
    await openSheet(tester);

    expect(find.text('Ambil foto'), findsOneWidget);
    expect(find.text('Pilih dari galeri'), findsOneWidget);
    expect(find.text('Hapus foto'), findsNothing);
  });

  testWidgets('sheet shows Hapus foto when a photo exists', (tester) async {
    await pump(tester, user: withoutPhoto.withAvatar('https://x/u/a.webp'));
    await openSheet(tester);

    expect(find.text('Hapus foto'), findsOneWidget);
  });

  testWidgets('deleting the photo asks for confirmation first', (tester) async {
    when(
      () => authRepository.updateAvatar(null),
    ).thenAnswer((_) async => const Right(null));
    await pump(tester, user: withoutPhoto.withAvatar('https://x/u/a.webp'));
    await openSheet(tester);

    await tester.tap(find.text('Hapus foto'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus foto profil?'), findsOneWidget);
    verifyNever(() => authRepository.updateAvatar(any()));

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    verifyNever(() => authRepository.updateAvatar(any()));

    await openSheet(tester);
    await tester.tap(find.text('Hapus foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    verify(() => authRepository.updateAvatar(null)).called(1);
    verify(() => authBloc.add(const AvatarUpdated(null))).called(1);
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('gallery pick is uploaded, saved and applied to the session', (
    tester,
  ) async {
    when(
      () => uploadRepository.uploadImage(any()),
    ).thenAnswer((_) async => const Right('https://x/u/new.webp'));
    when(
      () => authRepository.updateAvatar('https://x/u/new.webp'),
    ).thenAnswer((_) async => const Right('https://x/u/new.webp'));
    await pump(tester, picker: _FakePicker(const [file]));
    await openSheet(tester);

    await tester.tap(find.text('Pilih dari galeri'));
    await tester.pumpAndSettle();

    verify(() => uploadRepository.uploadImage(file)).called(1);
    verify(
      () => authBloc.add(const AvatarUpdated('https://x/u/new.webp')),
    ).called(1);
    expect(find.text('Foto profil berhasil diperbarui.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('a failed upload shows the message and leaves the session', (
    tester,
  ) async {
    when(
      () => uploadRepository.uploadImage(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('Gagal mengunggah.')));
    await pump(tester, picker: _FakePicker(const [file]));
    await openSheet(tester);

    await tester.tap(find.text('Pilih dari galeri'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal mengunggah.'), findsOneWidget);
    verifyNever(() => authRepository.updateAvatar(any()));
    verifyNever(() => authBloc.add(any()));
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    await pump(tester, picker: _FakePicker(const []));
    await openSheet(tester);

    await tester.tap(find.text('Pilih dari galeri'));
    await tester.pumpAndSettle();

    verifyNever(() => uploadRepository.uploadImage(any()));
  });

  testWidgets('Ganti password row opens the change-password screen', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Ganti password'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('menu lists personal settings only, Keluar at the bottom', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Foto profil'), findsOneWidget);
    expect(find.text('Ganti password'), findsOneWidget);
    expect(find.text('Pengaturan Absensi'), findsNothing);
    expect(find.text('Tentukan Titik Absen'), findsNothing);
    expect(find.widgetWithText(AppTaskButton, 'Keluar'), findsOneWidget);
  });

  testWidgets('Keluar asks for confirmation before logging out', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(AppTaskButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari Kawalo?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    verifyNever(() => authBloc.add(const LogoutRequested()));

    await tester.tap(find.widgetWithText(AppTaskButton, 'Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last);
    await tester.pumpAndSettle();
    verify(() => authBloc.add(const LogoutRequested())).called(1);
  });

  testWidgets('background access row summarises what is still missing', (
    tester,
  ) async {
    final service = _MockBackgroundAccessService();
    when(service.status).thenAnswer(
      (_) async => const BackgroundAccessStatus(
        grants: {
          BackgroundAccessItem.notifications: BackgroundAccessGrant.granted,
          BackgroundAccessItem.microphone: BackgroundAccessGrant.granted,
          BackgroundAccessItem.battery: BackgroundAccessGrant.askable,
        },
      ),
    );
    await pump(
      tester,
      createAccessCubit: () => BackgroundAccessCubit(service: service),
    );

    expect(find.text('Izin latar belakang'), findsOneWidget);
    expect(find.text('Baterai belum diizinkan'), findsOneWidget);
  });
}
