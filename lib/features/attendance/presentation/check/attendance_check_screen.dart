import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_module.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/widgets/attendance_check_views.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/ml_kit_face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_registration_screen.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_camera_view.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_errors.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';

/// Where the caller should go after the flow closes.
enum AttendanceCheckExit { openAttendanceList, openSchedule }

/// Check-in/out with face verification. Pops with an [AttendanceCheckExit]
/// when the user picked a follow-up screen, else null.
class AttendanceCheckScreen extends StatelessWidget {
  const AttendanceCheckScreen({
    required this.module,
    required this.faceRepository,
    super.key,
    this.cameraFactory,
    this.location = LocationService.instance,
    this.launcherService = const DefaultAppLauncherService(),
  });

  static const String routeName = AppRouteNames.attendanceCheck;

  final AttendanceCheckModule module;
  final FaceRepository faceRepository;

  /// Replaced by a fake in tests; defaults to [MlKitFaceCamera].
  final FaceCamera Function()? cameraFactory;
  final LocationService location;
  final AppLauncherService launcherService;

  static Route<AttendanceCheckExit?> route({
    required AttendanceCheckModule module,
    required FaceRepository faceRepository,
  }) => AppPageRoute.forwardBackward<AttendanceCheckExit?>(
    settings: const RouteSettings(name: routeName),
    builder: (_) =>
        AttendanceCheckScreen(module: module, faceRepository: faceRepository),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendanceCheckCubit(
        repository: module.repository,
        faceRepository: faceRepository,
        networkInfo: module.networkInfo,
        cameraFactory: cameraFactory ?? MlKitFaceCamera.new,
        location: location,
      )..load(),
      child: BlocBuilder<AttendanceCheckCubit, AttendanceCheckState>(
        builder: _build,
      ),
    );
  }

  Widget _build(BuildContext context, AttendanceCheckState state) {
    final cubit = context.read<AttendanceCheckCubit>();
    void exit([AttendanceCheckExit? to]) => Navigator.of(context).pop(to);
    void retryLoad() => unawaited(cubit.load());
    void scan() => unawaited(cubit.startScan());

    return switch (state) {
      AttendanceCheckLoading() => const Scaffold(
        body: Center(child: AppLoadingIndicator()),
      ),
      AttendanceCheckOffline() => faceErrorPage(
        AppActionableErrorData(
          icon: KawaloVectors.wifiOff01,
          title: 'Absensi butuh koneksi internet',
          message:
              'Verifikasi wajah dilakukan di server, jadi check-in dan '
              'check-out tidak bisa dicatat saat offline.',
          primaryActionLabel: 'Coba Lagi',
          onPrimaryAction: retryLoad,
          secondaryActionLabel: 'Kembali',
          onSecondaryAction: exit,
        ),
      ),
      AttendanceCheckLoadFailed(:final message) => faceErrorPage(
        AppActionableErrorData(
          icon: KawaloVectors.alertCircle,
          title: 'Gagal memuat data absensi',
          message: message,
          primaryActionLabel: 'Coba Lagi',
          onPrimaryAction: retryLoad,
          secondaryActionLabel: 'Kembali',
          onSecondaryAction: exit,
        ),
      ),
      AttendanceCheckServiceUnavailable() => faceServiceUnavailableView(
        onBack: exit,
      ),
      AttendanceCheckFaceNotRegistered(:final reregister) => FaceResultLayout(
        tone: FaceResultTone.neutral,
        icon: KawaloVectors.userShield01,
        title: reregister
            ? 'Wajah perlu didaftarkan ulang'
            : 'Wajah belum terdaftar',
        message: reregister
            ? 'Data wajah Anda tidak bisa dipakai lagi untuk verifikasi. '
                  'Daftarkan ulang wajah Anda, hanya sekitar 30 detik.'
            : 'Check-in dan check-out wajib memakai verifikasi wajah. '
                  'Daftarkan wajah Anda dulu, hanya sekitar 30 detik.',
        actions: [
          FaceResultAction(
            'Daftarkan Wajah',
            () => unawaited(_register(context, replaceExisting: reregister)),
          ),
          FaceResultAction('Nanti', exit, style: AppButtonColor.tonal),
        ],
      ),
      AttendanceCheckNoSchedule(:final date) => FaceResultLayout(
        tone: FaceResultTone.neutral,
        icon: KawaloVectors.calendar01,
        title: 'Tidak ada jadwal hari ini',
        message:
            'Anda tidak punya jadwal shift pada '
            '${AppDateFormat.formatWeekdayDate(date)}. Bila ini keliru, '
            'hubungi admin grup.',
        actions: [
          FaceResultAction(
            'Lihat Jadwal Kerja',
            () => exit(AttendanceCheckExit.openSchedule),
          ),
          FaceResultAction('Kembali', exit, style: AppButtonColor.tonal),
        ],
      ),
      AttendanceCheckCompleted(:final slot) => FaceResultLayout(
        tone: FaceResultTone.success,
        icon: KawaloVectors.checkmarkCircle01Filled,
        title: 'Absensi hari ini sudah lengkap',
        message: _completedMessage(slot),
        actions: [
          FaceResultAction(
            'Lihat Data Absensi',
            () => exit(AttendanceCheckExit.openAttendanceList),
          ),
          FaceResultAction('Kembali', exit, style: AppButtonColor.tonal),
        ],
      ),
      AttendanceCheckLocationFailed(:final result) => faceErrorPage(
        LocationActionableError.fromLocationResult(
          result,
          onDismiss: exit,
          onRetry: retryLoad,
          launcherService: launcherService,
          secondaryActionLabel: 'Kembali',
        ),
      ),
      AttendanceCheckReady() => AttendanceReadyView(
        state: state,
        now: DateTime.now(),
        onStart: scan,
        onClose: exit,
      ),
      AttendanceCheckScanning(
        :final slot,
        :final action,
        :final issue,
        :final canRequestManual,
      ) =>
        FaceCameraView(
          camera: cubit.camera,
          title: 'Verifikasi Wajah',
          hint: issue?.message ?? 'Wajah terdeteksi. Tahan sebentar',
          hintOk: issue == null,
          heading: 'Hadapkan wajah ke kamera',
          message:
              '${_actionLabel(action)} · ${slot.shiftName}\n'
              'Posisikan wajah di dalam oval.',
          cancelLabel: 'Batal',
          onCancel: exit,
          extraActionLabel: canRequestManual ? 'Lapor ke Admin' : null,
          onExtraAction: canRequestManual
              ? () => unawaited(
                  cubit.openManualRequest(ManualAttendanceReason.faceFailed),
                )
              : null,
        ),
      AttendanceCheckVerifying(:final slot, :final action) => PopScope(
        canPop: false,
        child: FaceCameraView(
          title: 'Verifikasi Wajah',
          hint: 'Wajah terdeteksi',
          hintOk: true,
          heading: 'Memverifikasi wajah dan lokasi...',
          message:
              '${_actionLabel(action)} · ${slot.shiftName}\n'
              'Mengirim foto dan lokasi ke server. Jangan tutup aplikasi.',
          cancelLabel: 'Batal',
          busy: true,
        ),
      ),
      AttendanceCheckSuccess(:final result) => AttendanceResultView(
        result: result,
        onDone: exit,
        onOpenList: () => exit(AttendanceCheckExit.openAttendanceList),
      ),
      AttendanceCheckFaceNotMatch() => FaceNotMatchView(
        state: state,
        onRetry: scan,
        onReport: () => unawaited(
          cubit.openManualRequest(ManualAttendanceReason.faceFailed),
        ),
        onBack: exit,
      ),
      AttendanceCheckOutOfRadius(:final message) => FaceResultLayout(
        tone: FaceResultTone.error,
        icon: KawaloVectors.locationOffline01,
        title: 'Di luar radius absen',
        message: message,
        actions: [
          FaceResultAction('Perbarui Lokasi', retryLoad),
          FaceResultAction('Kembali', exit, style: AppButtonColor.tonal),
        ],
      ),
      AttendanceCheckRejected(:final title, :final message) => FaceResultLayout(
        tone: FaceResultTone.error,
        icon: KawaloVectors.alertCircle,
        title: title,
        message: message,
        actions: [
          FaceResultAction('Coba Lagi', scan),
          FaceResultAction('Kembali', exit, style: AppButtonColor.tonal),
        ],
      ),
      AttendanceCheckSubmitFailed(:final message) => faceErrorPage(
        AppActionableErrorData(
          icon: KawaloVectors.cloudOff,
          title: 'Absensi belum terkirim',
          message: message,
          primaryActionLabel: 'Coba Lagi',
          onPrimaryAction: () => unawaited(cubit.resubmit()),
          secondaryActionLabel: 'Kembali',
          onSecondaryAction: exit,
        ),
      ),
      AttendanceCheckCameraFault(:final fault) => faceCameraFaultView(
        fault: fault,
        onRetry: scan,
        onOpenSettings: () => unawaited(launcherService.openAppSettings()),
        onBack: exit,
        secondaryLabel: 'Lapor ke Admin',
        onSecondary: () => unawaited(
          cubit.openManualRequest(ManualAttendanceReason.cameraUnavailable),
        ),
      ),
      AttendanceCheckManualRequest() => ManualRequestView(
        state: state,
        onSend: (note) => unawaited(cubit.sendManualRequest(note)),
        onCancel: cubit.cancelManualRequest,
      ),
      AttendanceCheckManualSent(:final alreadyPending) => FaceResultLayout(
        tone: FaceResultTone.success,
        icon: KawaloVectors.checkmarkCircle01Filled,
        title: alreadyPending ? 'Laporan sudah ada' : 'Laporan terkirim',
        message: alreadyPending
            ? 'Laporan Anda sebelumnya masih menunggu tinjauan admin grup.'
            : 'Admin grup akan meninjau laporan Anda dan mencatat absensi '
                  'secara manual bila disetujui.',
        actions: [FaceResultAction('Selesai', exit)],
      ),
    };
  }

  Future<void> _register(
    BuildContext context, {
    required bool replaceExisting,
  }) async {
    final cubit = context.read<AttendanceCheckCubit>();
    final registered = await Navigator.of(context).push(
      FaceRegistrationScreen.route(
        repository: faceRepository,
        replaceExisting: replaceExisting,
        fromAttendance: true,
        cameraFactory: cameraFactory,
      ),
    );
    if (registered ?? false) await cubit.load();
  }

  static String _actionLabel(AttendanceAction action) =>
      action == AttendanceAction.checkIn ? 'Check-in' : 'Check-out';

  static String _completedMessage(AttendanceSlot? slot) {
    final checkin = slot?.checkin;
    final checkout = slot?.checkout;
    if (slot == null || checkin == null || checkout == null) {
      return 'Anda sudah check-in dan check-out untuk shift hari ini.';
    }
    return 'Check-in pukul ${hhmm(checkin)} dan check-out pukul '
        '${hhmm(checkout)} untuk ${slot.shiftName} sudah tercatat.';
  }
}
