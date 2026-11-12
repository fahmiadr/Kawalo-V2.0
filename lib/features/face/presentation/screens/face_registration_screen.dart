import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/ml_kit_face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_state.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_camera_view.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_errors.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';

/// Consent, guide, capture, upload and outcome of the face registration.
/// Pops with `true` once the face is registered.
class FaceRegistrationScreen extends StatelessWidget {
  const FaceRegistrationScreen({
    required this.repository,
    super.key,
    this.replaceExisting = false,
    this.fromAttendance = false,
    this.cameraFactory,
    this.launcherService = const DefaultAppLauncherService(),
  });

  static const String routeName = AppRouteNames.faceRegistration;

  final FaceRepository repository;
  final bool replaceExisting;

  /// Opened from the attendance flow: the success button returns there.
  final bool fromAttendance;

  /// Replaced by a fake in tests; defaults to [MlKitFaceCamera].
  final FaceCamera Function()? cameraFactory;
  final AppLauncherService launcherService;

  static Route<bool> route({
    required FaceRepository repository,
    bool replaceExisting = false,
    bool fromAttendance = false,
    FaceCamera Function()? cameraFactory,
  }) => AppPageRoute.forwardBackward<bool>(
    settings: const RouteSettings(name: routeName),
    builder: (_) => FaceRegistrationScreen(
      repository: repository,
      replaceExisting: replaceExisting,
      fromAttendance: fromAttendance,
      cameraFactory: cameraFactory,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FaceRegistrationCubit(
        repository: repository,
        cameraFactory: cameraFactory ?? MlKitFaceCamera.new,
        replaceExisting: replaceExisting,
      ),
      child: BlocBuilder<FaceRegistrationCubit, FaceRegistrationState>(
        builder: (context, state) {
          final cubit = context.read<FaceRegistrationCubit>();
          void finish({required bool registered}) =>
              Navigator.of(context).pop(registered);
          void close() => finish(registered: false);
          return switch (state) {
            FaceRegistrationConsent() => _ConsentView(
              onAccept: cubit.acceptConsent,
              onDecline: close,
            ),
            FaceRegistrationIntro() => _IntroView(
              photoCount: cubit.photoTarget,
              onStart: () => unawaited(cubit.begin()),
              onLater: close,
            ),
            FaceRegistrationCapturing(
              :final captured,
              :final total,
              :final issue,
            ) =>
              FaceCameraView(
                camera: cubit.camera,
                title: 'Daftarkan Wajah',
                hint: issue?.message ?? 'Lihat lurus ke kamera',
                hintOk: issue == null,
                heading: 'Posisikan wajah di dalam oval',
                message: issue == FaceIssue.multipleFaces
                    ? 'Foto ${captured + 1} dari $total. Pastikan hanya Anda '
                          'di depan kamera.'
                    : 'Foto ${captured + 1} dari $total. Foto diambil '
                          'otomatis saat posisi sudah pas.',
                progress: (captured, total),
                cancelLabel: 'Batalkan Pendaftaran',
                onCancel: close,
              ),
            FaceRegistrationCameraFault(:final fault) => faceCameraFaultView(
              fault: fault,
              onRetry: () => unawaited(cubit.begin()),
              onOpenSettings: () =>
                  unawaited(launcherService.openAppSettings()),
              onBack: close,
            ),
            FaceRegistrationUploading(:final count) => _UploadingView(
              count: count,
            ),
            FaceRegistrationSuccess(:final accepted, :final submitted) =>
              FaceResultLayout(
                tone: FaceResultTone.success,
                icon: KawaloVectors.checkmarkCircle01Filled,
                title: accepted == null
                    ? 'Wajah sudah terdaftar'
                    : 'Wajah berhasil didaftarkan',
                message:
                    'Mulai sekarang check-in dan check-out memakai '
                    'verifikasi wajah.',
                content: [
                  if (accepted != null)
                    FaceInfoCard(
                      children: [
                        FaceInfoRow(
                          icon: KawaloVectors.userShield01,
                          label: 'Kualitas pendaftaran',
                          value: '$accepted dari $submitted foto lolos',
                        ),
                      ],
                    ),
                ],
                actions: [
                  FaceResultAction(
                    fromAttendance ? 'Lanjut ke Absensi' : 'Selesai',
                    () => finish(registered: true),
                  ),
                ],
              ),
            FaceRegistrationFailed(:final message) => FaceResultLayout(
              tone: FaceResultTone.error,
              icon: KawaloVectors.cancelCircleFilled,
              title: 'Pendaftaran wajah gagal',
              message:
                  'Wajah belum bisa diproses. Coba lagi di tempat yang lebih '
                  'terang dan lepas aksesori.',
              content: [
                FaceInfoCard(
                  children: [
                    FaceInfoRow(
                      icon: KawaloVectors.alertCircle,
                      label: 'Penyebab',
                      value: message,
                    ),
                    const FaceInfoRow(
                      icon: KawaloVectors.helpCircle,
                      label: 'Masih gagal?',
                      value: 'Hubungi admin grup Anda',
                    ),
                  ],
                ),
              ],
              actions: [
                FaceResultAction('Coba Lagi', () => unawaited(cubit.retry())),
                FaceResultAction('Nanti', close, style: AppButtonColor.tonal),
              ],
            ),
            FaceRegistrationServiceUnavailable() => faceServiceUnavailableView(
              onBack: close,
            ),
          };
        },
      ),
    );
  }
}

class _ConsentView extends StatefulWidget {
  const _ConsentView({required this.onAccept, required this.onDecline});

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_ConsentView> createState() => _ConsentViewState();
}

class _ConsentViewState extends State<_ConsentView> {
  bool _agreed = false;

  // DRAFT consent text (user decision 12 Nov 2026). The retention periods
  // (registration photos while active in the group, check-in/out photos for
  // 90 days) still await the team's decision; update them together with the
  // server's retention job. See Task/progress/absensi-check-in-out.md.
  static const List<(String, String, String)> _items = [
    (
      KawaloVectors.userShield01,
      'Yang disimpan',
      'Template numerik wajah (embedding) dan foto pendaftaran Anda, '
          'terenkripsi. Foto saat check-in dan check-out juga disimpan. Foto '
          'dari percobaan yang gagal tidak disimpan.',
    ),
    (
      KawaloVectors.checkmarkCircle01Filled,
      'Tujuan',
      'Memastikan Anda sendiri yang check-in dan check-out.',
    ),
    (
      KawaloVectors.view,
      'Siapa yang melihat',
      'Admin grup Anda dapat melihat foto pendaftaran dan foto check-in '
          'atau check-out Anda.',
    ),
    (
      KawaloVectors.clockHour5,
      'Lama penyimpanan',
      'Foto pendaftaran dan template wajah disimpan selama Anda aktif di grup, '
          'lalu dihapus saat Anda keluar atau diminta. Foto check-in dan '
          'check-out disimpan 90 hari.',
    ),
    (
      KawaloVectors.delete01,
      'Hak Anda',
      'Minta hapus kapan saja lewat Pengaturan > Data Wajah, atau hubungi admin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          semanticLabel: 'Tutup',
          onPressed: widget.onDecline,
          icon: const AppSvgIcon(KawaloVectors.cancel01),
        ),
        title: const Text('Data Wajah'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space200),
                children: [
                  Text(
                    'Persetujuan biometrik',
                    style: typeScale.labelLarge.copyWith(color: colors.primary),
                  ),
                  AppSpacing.vGap100,
                  Text(
                    'Izinkan Kawalo memakai data wajah Anda?',
                    style: emphasized.headlineSmall,
                  ),
                  AppSpacing.vGap200,
                  FaceInfoCard(
                    children: [
                      for (final (icon, label, value) in _items)
                        FaceInfoRow(icon: icon, label: label, value: value),
                    ],
                  ),
                  AppSpacing.vGap200,
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space100,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (v) =>
                                setState(() => _agreed = v ?? false),
                          ),
                          AppSpacing.hGap100,
                          Expanded(
                            child: Text(
                              'Saya mengerti dan menyetujui data wajah saya '
                              'diproses untuk verifikasi absensi.',
                              style: typeScale.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space200,
                AppSpacing.space150,
                AppSpacing.space200,
                AppSpacing.space300,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    size: AppButtonSize.md,
                    enabled: _agreed,
                    onPressed: widget.onAccept,
                    child: const Text('Setuju dan Lanjutkan'),
                  ),
                  AppSpacing.vGap100,
                  AppButton(
                    style: AppButtonColor.tonal,
                    size: AppButtonSize.md,
                    onPressed: widget.onDecline,
                    child: const Text('Tolak'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.photoCount,
    required this.onStart,
    required this.onLater,
  });

  final int photoCount;
  final VoidCallback onStart;
  final VoidCallback onLater;

  static const _tips = [
    ('Cahaya cukup', 'Cari tempat terang, hindari cahaya dari belakang.'),
    ('Wajah terlihat penuh', 'Lepas masker, kacamata gelap, dan topi.'),
    ('Hanya Anda', 'Pastikan tidak ada orang lain di depan kamera.'),
    ('Tatap kamera', 'Pegang ponsel setinggi mata dan lihat lurus.'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          semanticLabel: 'Tutup',
          onPressed: onLater,
          icon: const AppSvgIcon(KawaloVectors.cancel01),
        ),
        title: const Text('Daftarkan Wajah'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space200),
                children: [
                  Text('Siapkan diri Anda', style: emphasized.headlineSmall),
                  AppSpacing.vGap100,
                  Text(
                    '$photoCount foto · sekitar 30 detik',
                    style: typeScale.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGap200,
                  FaceInfoCard(
                    children: [
                      for (final (title, body) in _tips)
                        FaceInfoRow(
                          icon: KawaloVectors.checkmarkCircle01Filled,
                          label: title,
                          value: body,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space200,
                AppSpacing.space150,
                AppSpacing.space200,
                AppSpacing.space300,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    size: AppButtonSize.md,
                    onPressed: onStart,
                    child: const Text('Mulai'),
                  ),
                  AppSpacing.vGap100,
                  AppButton(
                    style: AppButtonColor.tonal,
                    size: AppButtonSize.md,
                    onPressed: onLater,
                    child: const Text('Nanti'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadingView extends StatelessWidget {
  const _UploadingView({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLoadingIndicator(),
                  AppSpacing.vGap300,
                  Text(
                    'Memproses wajah Anda',
                    textAlign: TextAlign.center,
                    style: emphasized.headlineSmall,
                  ),
                  AppSpacing.vGap100,
                  Text(
                    'Mengunggah $count foto dan membuat template wajah. '
                    'Jangan tutup aplikasi.',
                    textAlign: TextAlign.center,
                    style: typeScale.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGap200,
                  Text(
                    'Foto dan template wajah disimpan terenkripsi',
                    textAlign: TextAlign.center,
                    style: typeScale.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
