import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

/// Face mismatches after which "Lapor ke admin" is offered in addition to
/// retrying. Retrying itself is never limited.
const int manualOfferAfterFailures = 3;

/// The server counts failures (user decision b); its fields win. The local
/// count only covers a server that does not send them yet.
bool canRequestManualAttendance({
  required int localFailures,
  int? serverFailures,
  bool? serverAvailable,
}) =>
    serverAvailable ??
    (serverFailures ?? localFailures) >= manualOfferAfterFailures;

/// How long a face must pass the quality gate before the photo is taken.
const Duration faceStableDuration = Duration(seconds: 1);

/// Check-in/out: pre-checks (connection, face status, schedule, GPS), the
/// front camera that photographs a steady, well-positioned face, then one
/// `POST /attendance`. Nothing here can record attendance without the
/// server's face verification.
class AttendanceCheckCubit extends Cubit<AttendanceCheckState> {
  AttendanceCheckCubit({
    required this.repository,
    required this.faceRepository,
    required this.networkInfo,
    required this.cameraFactory,
    this.location = LocationService.instance,
    DateTime Function()? clock,
    this.stableDuration = faceStableDuration,
  }) : _clock = clock ?? DateTime.now,
       super(const AttendanceCheckLoading());

  final AttendanceCheckRepository repository;
  final FaceRepository faceRepository;
  final NetworkInfo networkInfo;
  final FaceCamera Function() cameraFactory;
  final LocationService location;
  final Duration stableDuration;
  final DateTime Function() _clock;

  AttendanceCheckReady? _ready;
  FaceCamera? _camera;
  StreamSubscription<FaceFrame>? _frames;
  Timer? _stableTimer;
  Future<LocationResult>? _freshLocation;
  LocationResult? _lastLocation;
  Uint8List? _photo;
  AttendanceCheckState? _beforeManual;
  bool _capturing = false;
  int _localFailures = 0;
  bool _manualAvailable = false;

  /// The running camera while scanning, for the preview.
  FaceCamera? get camera => _camera;

  Future<void> load() async {
    await _stopScan();
    _ready = null;
    emit(const AttendanceCheckLoading());
    if (!await networkInfo.isConnected) {
      if (!isClosed) emit(const AttendanceCheckOffline());
      return;
    }
    final now = _clock();
    final (status, slots, position) = await (
      faceRepository.getStatus(),
      repository.getSlots(now),
      location.getCurrentPosition(),
    ).wait;
    if (isClosed) return;
    _lastLocation = position;

    final FaceStatus face;
    switch (status) {
      case Left(value: final failure):
        return emit(_loadFailure(failure));
      case Right(:final value):
        face = value;
    }
    if (!face.available) return emit(const AttendanceCheckServiceUnavailable());
    if (!face.usable) {
      return emit(
        AttendanceCheckFaceNotRegistered(reregister: face.needsReregistration),
      );
    }
    final List<AttendanceSlot> schedule;
    switch (slots) {
      case Left(value: final failure):
        return emit(_loadFailure(failure));
      case Right(:final value):
        schedule = value;
    }
    final plan = planAttendance(schedule, now);
    final slot = plan.slot;
    final action = plan.action;
    if (slot == null) {
      return emit(
        AttendanceCheckNoSchedule(DateTime(now.year, now.month, now.day)),
      );
    }
    if (action == null) return emit(AttendanceCheckCompleted(slot));
    if (!position.isSafe) return emit(AttendanceCheckLocationFailed(position));
    final ready = AttendanceCheckReady(
      slot: slot,
      action: action,
      accuracyMeters: position.position?.accuracy,
    );
    _ready = ready;
    emit(ready);
  }

  AttendanceCheckState _loadFailure(Failure failure) {
    if (failure is NoInternetFailure) return const AttendanceCheckOffline();
    if (failure.errorCode == FaceErrorCodes.serviceUnavailable) {
      return const AttendanceCheckServiceUnavailable();
    }
    return AttendanceCheckLoadFailed(failure.message);
  }

  /// Opens the camera; the photo is taken once the face has been well
  /// positioned for [stableDuration]. Also starts a fresh GPS fix in parallel
  /// so the submitted position is current.
  Future<void> startScan() async {
    final ready = _ready;
    if (ready == null) return;
    await _stopScan();
    _photo = null;
    _capturing = false;
    _freshLocation = location.getCurrentPosition();
    // Created before the emit so the first build already has the preview.
    final camera = _camera = cameraFactory();
    emit(
      AttendanceCheckScanning(
        slot: ready.slot,
        action: ready.action,
        canRequestManual: _manualAvailable,
      ),
    );
    try {
      await camera.start();
    } on FaceCameraException catch (e) {
      await _stopScan();
      if (!isClosed) emit(AttendanceCheckCameraFault(e.fault));
      return;
    }
    if (isClosed) return;
    _frames = camera.frames.listen(onFrame);
    unawaited(_refreshManualAvailability());
  }

  // The nonce is only read for the server's failure tally and then left to
  // expire; the one used for submit is issued after the photo is taken.
  Future<void> _refreshManualAvailability() async {
    final nonce = await repository.issueNonce();
    final available = nonce.toNullable()?.manualRequestAvailable;
    final current = state;
    if (isClosed || available == null) return;
    _manualAvailable = available;
    if (current is AttendanceCheckScanning &&
        current.canRequestManual != available) {
      emit(
        AttendanceCheckScanning(
          slot: current.slot,
          action: current.action,
          issue: current.issue,
          canRequestManual: available,
        ),
      );
    }
  }

  Future<void> onFrame(FaceFrame frame) async {
    final current = state;
    final ready = _ready;
    if (current is! AttendanceCheckScanning || ready == null || _capturing) {
      return;
    }
    final issue = faceIssue(frame);
    if (issue == null) {
      _stableTimer ??= Timer(stableDuration, _onStable);
    } else {
      _stableTimer?.cancel();
      _stableTimer = null;
    }
    final next = AttendanceCheckScanning(
      slot: ready.slot,
      action: ready.action,
      issue: issue,
      canRequestManual: _manualAvailable,
    );
    if (next != current) emit(next);
  }

  void _onStable() {
    _stableTimer = null;
    if (state is AttendanceCheckScanning && !_capturing) {
      unawaited(_captureAndSubmit());
    }
  }

  Future<void> _captureAndSubmit() async {
    _capturing = true;
    final Uint8List photo;
    try {
      photo = await _camera!.capture();
    } on FaceCameraException catch (e) {
      await _stopScan();
      if (!isClosed) emit(AttendanceCheckCameraFault(e.fault));
      return;
    }
    await _stopScan();
    _photo = photo;
    await _submit();
  }

  /// "Coba Lagi" after a network failure: the same photo, a new nonce.
  Future<void> resubmit() => _photo == null ? startScan() : _submit();

  Future<void> _submit() async {
    final ready = _ready;
    final photo = _photo;
    if (ready == null || photo == null || isClosed) return;
    emit(AttendanceCheckVerifying(slot: ready.slot, action: ready.action));
    final position = await (_freshLocation ?? location.getCurrentPosition());
    _freshLocation = null;
    if (isClosed) return;
    _lastLocation = position;
    final coordinates = position.coordinates;
    if (!position.isSafe || coordinates == null) {
      return emit(AttendanceCheckLocationFailed(position));
    }
    final (latitude, longitude) = coordinates;

    // A nonce can expire while the photo is sent; one fresh retry is
    // invisible to the user.
    for (var attempt = 0; ; attempt++) {
      final issued = await repository.issueNonce();
      if (isClosed) return;
      final AttendanceNonce nonce;
      switch (issued) {
        case Left(value: final failure):
          return emit(_submitFailure(failure));
        case Right(:final value):
          nonce = value;
      }
      _manualAvailable = nonce.manualRequestAvailable ?? _manualAvailable;
      final result = await repository.submit(
        photo: photo,
        latitude: latitude,
        longitude: longitude,
        nonce: nonce.value,
      );
      if (isClosed) return;
      switch (result) {
        case Right(value: final done):
          _photo = null;
          return emit(AttendanceCheckSuccess(done));
        case Left(value: final failure)
            when failure.errorCode == AttendanceCheckErrorCodes.nonceInvalid &&
                attempt == 0:
          continue;
        case Left(value: final failure):
          return emit(_submitFailure(failure));
      }
    }
  }

  AttendanceCheckState _submitFailure(Failure failure) {
    if (failure is FaceNotMatchFailure) {
      _photo = null;
      _localFailures++;
      _manualAvailable = canRequestManualAttendance(
        localFailures: _localFailures,
        serverFailures: failure.failedAttempts,
        serverAvailable: failure.manualRequestAvailable,
      );
      return AttendanceCheckFaceNotMatch(
        message: failure.message,
        failedAttempts: failure.failedAttempts ?? _localFailures,
        canRequestManual: _manualAvailable,
      );
    }
    final now = _clock();
    final rejected = switch (failure.errorCode) {
      FaceErrorCodes.serviceUnavailable =>
        const AttendanceCheckServiceUnavailable(),
      FaceErrorCodes.notRegistered => const AttendanceCheckFaceNotRegistered(
        reregister: true,
      ),
      FaceErrorCodes.qualityLow => AttendanceCheckRejected(
        title: 'Foto wajah kurang jelas',
        message: failure.message,
      ),
      AttendanceCheckErrorCodes.noSchedule => AttendanceCheckNoSchedule(
        DateTime(now.year, now.month, now.day),
      ),
      AttendanceCheckErrorCodes.alreadyCompleted =>
        const AttendanceCheckCompleted(null),
      AttendanceCheckErrorCodes.outOfRadius => AttendanceCheckOutOfRadius(
        failure.message,
      ),
      AttendanceCheckErrorCodes.nonceInvalid => AttendanceCheckRejected(
        title: 'Sesi absensi kedaluwarsa',
        message: failure.message,
      ),
      _ => null,
    };
    if (rejected != null) {
      _photo = null;
      return rejected;
    }
    final status = failure.statusCode;
    if (failure is NetworkFailure ||
        status == 429 ||
        (status != null && status >= 500)) {
      return AttendanceCheckSubmitFailed(failure.message);
    }
    _photo = null;
    return AttendanceCheckRejected(
      title: 'Absensi gagal',
      message: failure.message,
    );
  }

  Future<void> openManualRequest(ManualAttendanceReason reason) async {
    final before = state;
    if (before is AttendanceCheckScanning) {
      if (_capturing) return;
      await _stopScan();
    }
    _beforeManual = before;
    emit(AttendanceCheckManualRequest(reason));
  }

  void cancelManualRequest() {
    final previous = _beforeManual;
    if (previous is AttendanceCheckScanning) {
      unawaited(startScan());
    } else if (previous != null) {
      emit(previous);
    }
  }

  Future<void> sendManualRequest(String? note) async {
    final current = state;
    if (current is! AttendanceCheckManualRequest || current.sending) return;
    emit(AttendanceCheckManualRequest(current.reason, sending: true));
    var position = _lastLocation;
    if (position == null || !position.isSafe) {
      position = await location.getCurrentPosition();
      _lastLocation = position;
    }
    if (isClosed) return;
    final coordinates = position.coordinates;
    if (!position.isSafe || coordinates == null) {
      return emit(
        AttendanceCheckManualRequest(
          current.reason,
          error:
              position.errorMessage ??
              'Lokasi tidak tersedia. Aktifkan GPS lalu coba lagi.',
        ),
      );
    }
    final (latitude, longitude) = coordinates;
    final result = await repository.requestManual(
      reason: current.reason,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
    if (isClosed) return;
    result.match(
      (failure) => emit(
        failure.statusCode == 409
            ? const AttendanceCheckManualSent(alreadyPending: true)
            : AttendanceCheckManualRequest(
                current.reason,
                error: failure.message,
              ),
      ),
      (_) => emit(const AttendanceCheckManualSent(alreadyPending: false)),
    );
  }

  Future<void> _stopScan() async {
    _stableTimer?.cancel();
    _stableTimer = null;
    final camera = _camera;
    _camera = null;
    await _frames?.cancel();
    _frames = null;
    await camera?.dispose();
  }

  @override
  Future<void> close() async {
    _photo = null;
    await _stopScan();
    return await super.close();
  }
}
