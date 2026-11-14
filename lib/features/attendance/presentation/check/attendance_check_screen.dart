import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/duration_text.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_module.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/widgets/attendance_check_views.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/ml_kit_face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_registration_screen.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_camera_view.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_errors.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

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
      child: _AttendanceCheckBody(screen: this),
    );
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

/// Maps the cubit states to the redesign screens. Ready opens the camera at
/// once (the home card already asked "Check-in dengan Wajah"); an early
/// check-out is confirmed first (`RdBerandaLainnyaPulangAwal`), once per visit.
class _AttendanceCheckBody extends StatefulWidget {
  const _AttendanceCheckBody({required this.screen});

  final AttendanceCheckScreen screen;

  @override
  State<_AttendanceCheckBody> createState() => _AttendanceCheckBodyState();
}

class _AttendanceCheckBodyState extends State<_AttendanceCheckBody> {
  bool _earlyCheckoutConfirmed = false;
  AttendanceAction? _action;
  String? _shiftName;

  AttendanceCheckScreen get _screen => widget.screen;

  void _exit([AttendanceCheckExit? to]) => Navigator.of(context).pop(to);

  Future<void> _onReady(AttendanceCheckReady ready) async {
    final cubit = context.read<AttendanceCheckCubit>();
    final now = DateTime.now();
    final early = earlyCheckoutMinutes(ready.slot, ready.action, now);
    if (early != null && !_earlyCheckoutConfirmed) {
      final confirmed = await showTaskConfirmDialog(
        context: context,
        title: 'Pulang lebih awal?',
        message:
            'Shift selesai pukul ${dotTime(ready.slot.endsAt)}. Check-out '
            'sekarang (${dotTime(now)}) tercatat pulang lebih awal '
            '${formatMinutes(early)}.',
        confirmLabel: 'Tetap Check-out',
        tone: KawaloTones.of(context).abs,
      );
      if (!mounted) return;
      if (!confirmed) return _exit();
      _earlyCheckoutConfirmed = true;
    }
    await cubit.startScan();
  }

  static String _pill(AttendanceSlot slot) {
    final place = slot.locationName;
    return place == null || place.isEmpty ? slot.shiftName : place;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCheckCubit, AttendanceCheckState>(
      listenWhen: (_, current) => current is AttendanceCheckReady,
      listener: (context, state) {
        if (state is AttendanceCheckReady) {
          setState(() {
            _action = state.action;
            _shiftName = state.slot.shiftName;
          });
          unawaited(_onReady(state));
        }
      },
      builder: _build,
    );
  }

  Widget _build(BuildContext context, AttendanceCheckState state) {
    final cubit = context.read<AttendanceCheckCubit>();
    void exit([AttendanceCheckExit? to]) => _exit(to);
    void retryLoad() => unawaited(cubit.load());
    void scan() => unawaited(cubit.startScan());
    final action = _action;
    final screenTitle = action == null
        ? 'Absensi'
        : AttendanceCheckScreen._actionLabel(action);

    return switch (state) {
      AttendanceCheckLoading() => TaskScaffold(
        title: screenTitle,
        onClose: exit,
        scrollable: false,
        body: const Center(child: AppLoadingIndicator()),
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
        title: screenTitle,
        neutral: true,
        onClose: exit,
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
        title: screenTitle,
        onClose: exit,
      ),
      AttendanceCheckServiceUnavailable() => faceServiceUnavailableView(
        onBack: exit,
        title: screenTitle,
      ),
      AttendanceCheckFaceNotRegistered(:final reregister) => FaceResultLayout(
        screenTitle: screenTitle,
        onClose: exit,
        tone: FaceResultTone.success,
        icon: KawaloVectors.userShield01,
        title: reregister ? 'Daftarkan ulang wajah' : 'Daftarkan wajah dulu',
        message: reregister
            ? 'Data wajah Anda tidak bisa dipakai lagi untuk verifikasi. '
                  'Daftarkan ulang, sekitar 30 detik.'
            : 'Sekali saja, sekitar 30 detik. Setelah itu check-in cukup '
                  'menghadap kamera.',
        actions: [
          FaceResultAction(
            'Daftarkan Wajah',
            () => unawaited(
              _screen._register(context, replaceExisting: reregister),
            ),
          ),
        ],
      ),
      AttendanceCheckNoSchedule(:final date) => FaceResultLayout(
        screenTitle: screenTitle,
        onClose: exit,
        tone: FaceResultTone.neutral,
        icon: KawaloVectors.calendar01,
        title: 'Tidak ada jadwal hari ini',
        message:
            'Anda tidak punya jadwal shift pada '
            '${AppDateFormat.formatWeekdayDate(date)}. Bila ini keliru, '
            'hubungi admin grup.',
        actions: [
          FaceResultAction(
            'Lihat Jadwal Saya',
            () => exit(AttendanceCheckExit.openSchedule),
          ),
        ],
      ),
      AttendanceCheckCompleted(:final slot) => FaceResultLayout(
        tone: FaceResultTone.success,
        icon: KawaloVectors.check,
        title: 'Absensi hari ini selesai',
        message: AttendanceCheckScreen._completedMessage(slot),
        actions: [
          FaceResultAction('Kembali ke Beranda', exit),
          FaceResultAction(
            'Lihat Riwayat Absen',
            () => exit(AttendanceCheckExit.openAttendanceList),
            style: AppButtonColor.tonal,
          ),
        ],
      ),
      AttendanceCheckLocationFailed(:final result) => faceErrorPage(
        LocationActionableError.fromLocationResult(
          result,
          onDismiss: exit,
          onRetry: retryLoad,
          launcherService: _screen.launcherService,
          secondaryActionLabel: 'Kembali',
        ),
        title: screenTitle,
        onClose: exit,
      ),
      AttendanceCheckReady(:final slot) => FaceCameraView(
        title: screenTitle,
        hint: 'Menyiapkan kamera…',
        hintOk: false,
        busy: true,
        pill: _pill(slot),
        pillIcon: Icons.location_on_outlined,
        cancelLabel: 'Tutup',
        onCancel: exit,
      ),
      AttendanceCheckScanning(
        :final slot,
        :final action,
        :final issue,
        :final canRequestManual,
      ) =>
        FaceCameraView(
          camera: cubit.camera,
          title: AttendanceCheckScreen._actionLabel(action),
          hint: switch (issue) {
            null => 'Tahan sebentar…',
            FaceIssue.noFace => 'Posisikan wajah di dalam oval',
            _ => issue.message,
          },
          hintOk: issue == null,
          pill: _pill(slot),
          pillIcon: Icons.location_on_outlined,
          caption: 'Foto tidak disimpan bila gagal',
          cancelLabel: 'Tutup',
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
          title: AttendanceCheckScreen._actionLabel(action),
          hint: 'Mencocokkan wajah…',
          hintOk: true,
          busy: true,
          pill: _pill(slot),
          pillIcon: Icons.location_on_outlined,
          caption: 'Mengirim foto dan lokasi. Jangan tutup aplikasi.',
          cancelLabel: 'Tutup',
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
        screenTitle: screenTitle,
        onClose: exit,
        tone: FaceResultTone.error,
        icon: KawaloVectors.locationOffline01,
        title: 'Di luar radius absen',
        message: message,
        actions: [FaceResultAction('Periksa Lagi', retryLoad)],
      ),
      AttendanceCheckRejected(title: final rejected, :final message) =>
        FaceResultLayout(
          screenTitle: screenTitle,
          onClose: exit,
          tone: FaceResultTone.error,
          icon: KawaloVectors.alertCircle,
          title: rejected,
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
        title: screenTitle,
        onClose: exit,
      ),
      AttendanceCheckCameraFault(:final fault) => faceCameraFaultView(
        fault: fault,
        title: screenTitle,
        onRetry: scan,
        onOpenSettings: () =>
            unawaited(_screen.launcherService.openAppSettings()),
        onBack: exit,
        secondaryLabel: 'Lapor ke Admin',
        onSecondary: () => unawaited(
          cubit.openManualRequest(ManualAttendanceReason.cameraUnavailable),
        ),
      ),
      AttendanceCheckManualRequest() => ManualRequestView(
        state: state,
        subtitle: action == null
            ? null
            : '$screenTitle ${_shiftName ?? ''}'.trim(),
        onSend: (note) => unawaited(cubit.sendManualRequest(note)),
        onCancel: cubit.cancelManualRequest,
      ),
      AttendanceCheckManualSent(:final alreadyPending) => ManualSentView(
        alreadyPending: alreadyPending,
        onDone: exit,
      ),
    };
  }
}
