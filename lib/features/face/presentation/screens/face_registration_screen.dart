import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/ml_kit_face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_state.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_camera_view.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_errors.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

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
                hint: switch (issue) {
                  null => 'Lihat lurus ke kamera',
                  FaceIssue.noFace => 'Posisikan wajah di dalam oval',
                  _ => issue.message,
                },
                hintOk: issue == null,
                hintBad: issue != null && issue != FaceIssue.noFace,
                pill: 'Foto ${captured + 1} dari $total',
                pillKind: issue != null && issue != FaceIssue.noFace
                    ? FaceCameraPillKind.bad
                    : FaceCameraPillKind.neutral,
                progress: (captured, total),
                cancelLabel: 'Batalkan Pendaftaran',
                onCancel: close,
              ),
            FaceRegistrationCameraFault(:final fault) => faceCameraFaultView(
              fault: fault,
              title: 'Daftarkan Wajah',
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
                icon: KawaloVectors.check,
                title: accepted == null
                    ? 'Wajah sudah terdaftar'
                    : 'Wajah terdaftar',
                message: accepted == null
                    ? 'Mulai sekarang check-in dan check-out memakai '
                          'verifikasi wajah.'
                    : '$accepted dari $submitted foto lolos dan tersimpan '
                          'terenkripsi. Sekarang Anda bisa check-in.',
                actions: [
                  FaceResultAction(
                    fromAttendance ? 'Lanjut Check-in' : 'Selesai',
                    () => finish(registered: true),
                  ),
                ],
              ),
            FaceRegistrationFailed(:final message) => FaceResultLayout(
              tone: FaceResultTone.error,
              icon: KawaloVectors.cancel01,
              title: 'Pendaftaran wajah gagal',
              message:
                  'Coba lagi di tempat yang lebih terang dan lepas aksesori. '
                  'Masih gagal? Hubungi admin grup Anda.',
              content: [
                FaceInfoCard(
                  children: [
                    FaceInfoRow(
                      icon: KawaloVectors.alertCircle,
                      label: 'Penyebab',
                      value: message,
                    ),
                  ],
                ),
              ],
              onClose: close,
              actions: [
                FaceResultAction('Coba Lagi', () => unawaited(cubit.retry())),
                FaceResultAction('Nanti', close, style: AppButtonColor.tonal),
              ],
            ),
            FaceRegistrationServiceUnavailable() => faceServiceUnavailableView(
              onBack: close,
              title: 'Data Wajah',
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

  static const List<(IconData, String, String)> _summary = [
    (
      Icons.lock_outline_rounded,
      'Yang disimpan',
      'Pola wajah dan foto, terenkripsi',
    ),
    (Icons.shield_outlined, 'Tujuan', 'Memastikan Anda sendiri yang absen'),
    (Icons.visibility_outlined, 'Siapa yang melihat', 'Admin grup Anda'),
    (
      Icons.delete_outline_rounded,
      'Bisa dihapus',
      'Kapan saja dari Data Wajah',
    ),
  ];

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

  Future<void> _readMore() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: KawaloTones.of(context).surface,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Persetujuan biometrik',
              style: TextStyle(
                color: KawaloTones.of(context).ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FaceInfoCard(
              children: [
                for (final (icon, label, value) in _items)
                  FaceInfoRow(icon: icon, label: label, value: value),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return TaskScaffold(
      title: 'Data Wajah',
      onClose: widget.onDecline,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Izinkan Kawalo memakai wajah Anda?',
            style: TextStyle(
              color: tones.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          for (final (icon, title, value) in _summary) ...[
            TaskListItem(
              title: title,
              subtitle: value,
              leading: TaskIconTile(icon, tone: tones.abs),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: AppTaskButton(
              label: 'Baca selengkapnya',
              variant: AppTaskButtonVariant.secondary,
              size: AppTaskButtonSize.small,
              onPressed: () => unawaited(_readMore()),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _agreed = !_agreed),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    activeColor: tones.abs.color,
                    checkColor: tones.abs.on,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Saya mengerti dan menyetujui data wajah saya diproses '
                      'untuk verifikasi absensi.',
                      style: TextStyle(color: tones.ink, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      footer: [
        taskPrimary(
          'Setuju dan Daftarkan',
          _agreed ? widget.onAccept : null,
          tone: tones.abs,
        ),
        taskSecondary('Tidak Sekarang', widget.onDecline),
      ],
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
    final tones = KawaloTones.of(context);
    return TaskScaffold(
      title: 'Daftarkan Wajah',
      subtitle: '$photoCount foto · sekitar 30 detik',
      onClose: onLater,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Siapkan diri Anda',
            style: TextStyle(
              color: tones.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          FaceInfoCard(
            children: [
              for (final (title, body) in _tips)
                FaceInfoRow(
                  icon: KawaloVectors.check,
                  label: title,
                  value: body,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Foto diambil otomatis saat wajah sudah pas di dalam oval.',
            style: TextStyle(color: tones.ink2, fontSize: 14),
          ),
        ],
      ),
      footer: [taskPrimary('Mulai', onStart, tone: tones.abs)],
    );
  }
}

class _UploadingView extends StatelessWidget {
  const _UploadingView({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: tones.background,
        body: SafeArea(
          child: TaskMessage(
            round: true,
            icon: SizedBox.square(
              dimension: 44,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: tones.abs.color,
              ),
            ),
            title: 'Memproses wajah Anda',
            message:
                'Mengunggah $count foto dan membuat template wajah. Jangan '
                'tutup aplikasi. Foto dan template wajah disimpan terenkripsi.',
          ),
        ),
      ),
    );
  }
}
