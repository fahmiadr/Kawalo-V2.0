import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/cubit/theme_mode_cubit.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/profile_avatar_cubit.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/change_password_screen.dart';
import 'package:kawalo_mobile/features/face/face_module.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_data_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/app_version_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/background_access_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/theme_mode_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/account_menu_row.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/background_access_sheet.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/profile_avatar_sheet.dart';

/// "Akun" (opened from the Beranda "Lainnya" card): profile of the signed-in
/// user and personal settings (photo, password, theme, face data, group,
/// background access), with "Keluar" pinned at the bottom. Admin settings
/// live in "Kelola".
///
/// Reads [AuthBloc] only for [Authenticated]; transient states (loading during
/// logout/switch) keep showing the last profile instead of flashing empty.
class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    this.mediaPicker,
    this.createBackgroundAccessCubit,
  });

  /// Test injection; defaults to the device camera and gallery.
  final MediaPickerService? mediaPicker;

  /// Test injection; defaults to the native background-access channel.
  final BackgroundAccessCubit Function()? createBackgroundAccessCubit;

  static Route<void> route() => AppPageRoute.slideFade<void>(
    settings: const RouteSettings(name: AppRouteNames.account),
    builder: (context) {
      final tones = KawaloTones.of(context);
      return Scaffold(
        backgroundColor: tones.background,
        appBar: AppBar(
          backgroundColor: tones.background,
          scrolledUnderElevation: 0,
          title: const Text('Akun'),
        ),
        body: const MoreScreen(),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    // The shell tolerates a missing AuthBloc (isolated widget tests); nothing
    // here works without one, so render nothing instead of throwing.
    if (context.read<AuthBloc?>() == null) return const SizedBox.shrink();
    final authRepository = context.read<AuthRepository?>();
    final uploadRepository = context.read<UploadRepository?>();
    final body = MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppVersionCubit()..load()),
        if (BackgroundAccessSheet.isSupported)
          BlocProvider(
            create: (_) =>
                (createBackgroundAccessCubit ?? BackgroundAccessCubit.new)()
                  ..load(),
          ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (_, current) => current is Authenticated,
        builder: (context, state) {
          final auth = state is Authenticated ? state : null;
          return _MoreBody(
            user: auth?.user,
            role: auth?.session?.role,
            mediaPicker: mediaPicker,
          );
        },
      ),
    );
    // Without both repositories (isolated widget tests) the photo stays
    // read-only.
    if (authRepository == null || uploadRepository == null) return body;
    return BlocProvider(
      create: (_) => ProfileAvatarCubit(
        authRepository: authRepository,
        uploadRepository: uploadRepository,
      ),
      child: BlocConsumer<ProfileAvatarCubit, ProfileAvatarState>(
        listener: _onAvatarState,
        builder: (context, state) => Stack(
          children: [
            body,
            if (state is ProfileAvatarBusy)
              const AppLoadingOverlay(semanticLabel: 'Menyimpan foto profil'),
          ],
        ),
      ),
    );
  }

  static void _onAvatarState(BuildContext context, ProfileAvatarState state) {
    switch (state) {
      case ProfileAvatarSuccess(:final avatarUrl, :final message):
        context.read<AuthBloc>().add(AvatarUpdated(avatarUrl));
        AppSnackbar.show(context, message: message);
      case ProfileAvatarFailure(:final message):
        AppSnackbar.show(context, message: message);
      case ProfileAvatarIdle():
      case ProfileAvatarBusy():
        break;
    }
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody({
    required this.user,
    required this.role,
    required this.mediaPicker,
  });

  final UserEntity? user;
  final String? role;
  final MediaPickerService? mediaPicker;

  static String? _roleLabel(String? role) {
    final value = role?.trim() ?? '';
    return switch (value.toUpperCase()) {
      '' => null,
      'ADMIN' => 'Admin',
      'GUARD' => 'Petugas',
      'USER' => 'Pengguna',
      _ => value,
    };
  }

  Future<void> _changeAvatar(BuildContext context, UserEntity user) async {
    final cubit = context.read<ProfileAvatarCubit>();
    final hasPhoto = user.avatarUrl?.trim().isNotEmpty ?? false;
    final action = await ProfileAvatarSheet.show(context, hasPhoto: hasPhoto);
    if (action == null || !context.mounted) return;

    if (action == ProfileAvatarAction.remove) {
      final confirmed = await showAppConfirmationDialog(
        context: context,
        title: 'Hapus foto profil?',
        message: 'Foto profil Anda akan dihapus dan diganti inisial nama.',
      );
      if ((confirmed ?? false) && !cubit.isClosed) {
        unawaited(cubit.removePhoto());
      }
      return;
    }

    final picker = mediaPicker ?? DefaultMediaPickerService();
    try {
      final files = action == ProfileAvatarAction.camera
          ? await picker.captureMultiImagesFromCamera(context, maxPhotos: 1)
          : await picker.pickMultiImagesFromGallery(limit: 1);
      if (files.isNotEmpty && !cubit.isClosed) {
        unawaited(cubit.setPhoto(files.first));
      }
    } on Object catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: action == ProfileAvatarAction.camera
              ? 'Kamera tidak dapat dibuka.'
              : 'Galeri tidak dapat dibuka.',
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Keluar dari Kawalo?',
      message:
          'Walkie-talkie berhenti dan data yang tersimpan di HP ini dihapus.',
      confirmText: 'Keluar',
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  Future<void> _openBackgroundAccess(BuildContext context) async {
    await BackgroundAccessSheet.show(context);
    if (context.mounted) {
      unawaited(context.read<BackgroundAccessCubit>().load());
    }
  }

  static String? _accessSummary(BackgroundAccessState state) {
    final grants = state.status?.grants;
    if (grants == null) return null;
    const names = {
      BackgroundAccessItem.notifications: 'Notifikasi',
      BackgroundAccessItem.microphone: 'Mikrofon',
      BackgroundAccessItem.battery: 'Baterai',
    };
    final missing = [
      for (final item in BackgroundAccessItem.values)
        if (grants[item] != BackgroundAccessGrant.granted) names[item]!,
    ];
    if (missing.isEmpty) return 'Semua diizinkan';
    return '${missing.join(', ')} belum diizinkan';
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final user = this.user;
    final groupName = user?.activeGroup?.groupName?.trim() ?? '';
    final roleLabel = _roleLabel(role ?? user?.activeGroup?.category);
    final caption = [
      ?roleLabel,
      if (groupName.isNotEmpty) groupName,
    ].join(' · ');
    final canChangePhoto =
        user != null && context.read<ProfileAvatarCubit?>() != null;
    final hasAccessCubit = context.read<BackgroundAccessCubit?>() != null;

    final rows = <Widget>[
      if (canChangePhoto)
        AccountMenuRow(
          icon: Icons.person_outline_rounded,
          title: 'Foto profil',
          onTap: () => unawaited(_changeAvatar(context, user)),
        ),
      if (context.read<AuthRepository?>() != null)
        AccountMenuRow(
          icon: Icons.key_outlined,
          title: 'Ganti password',
          onTap: () => Navigator.of(context).push(
            ChangePasswordScreen.route(
              repository: context.read<AuthRepository>(),
              authBloc: context.read<AuthBloc>(),
            ),
          ),
        ),
      if (context.read<ThemeModeCubit?>() != null)
        BlocBuilder<ThemeModeCubit, ThemeMode>(
          builder: (context, mode) => AccountMenuRow(
            icon: Icons.dark_mode_outlined,
            title: 'Tampilan',
            subtitle: ThemeModeScreen.label(mode),
            onTap: () => Navigator.of(context).push(ThemeModeScreen.route()),
          ),
        ),
      if (context.read<FaceModule?>() != null)
        AccountMenuRow(
          icon: Icons.face_outlined,
          title: 'Data wajah',
          subtitle: 'Status dan daftar ulang wajah',
          onTap: () => Navigator.of(context).push(
            FaceDataScreen.route(
              repository: context.read<FaceModule>().repository,
            ),
          ),
        ),
      if (user != null && user.groups.length > 1)
        AccountMenuRow(
          icon: Icons.swap_horiz_rounded,
          title: 'Ganti grup',
          subtitle: '${user.groups.length} grup',
          onTap: () =>
              unawaited(AppRouter.of(context).pushGroupSelection(user)),
        ),
      if (hasAccessCubit)
        BlocBuilder<BackgroundAccessCubit, BackgroundAccessState>(
          builder: (context, state) => AccountMenuRow(
            icon: Icons.battery_std_outlined,
            title: 'Izin latar belakang',
            subtitle: _accessSummary(state),
            onTap: () => unawaited(_openBackgroundAccess(context)),
          ),
        ),
    ];

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              children: [
                if (user != null) ...[
                  Row(
                    children: [
                      _Avatar(
                        name: user.name,
                        imageUrl: user.avatarUrl,
                        onTap: canChangePhoto
                            ? () => unawaited(_changeAvatar(context, user))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tones.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              caption.isEmpty ? user.email : caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: tones.ink2, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                for (final row in rows) ...[row, const SizedBox(height: 8)],
                BlocBuilder<AppVersionCubit, String?>(
                  builder: (context, version) => version == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Versi $version',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tones.ink3, fontSize: 12),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: AppTaskButton(
              label: 'Keluar',
              icon: Icons.logout_rounded,
              // Destructive but recoverable (sign in again), so the soft SOS
              // fill of `.btn.dan` instead of the solid one.
              tone: KawaloTone(
                color: tones.sos.soft,
                on: tones.sos.color,
                soft: tones.sos.soft,
              ),
              onPressed: () => unawaited(_confirmLogout(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = AppUserAvatar(
      name: name,
      imageUrl: imageUrl,
      size: 64,
      maxInitials: 2,
      circle: true,
    );
    if (onTap == null) return avatar;
    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatar,
      ),
    );
  }
}
