import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_state.dart';

/// Consent, then automatic capture of [photoTarget] photos that pass the
/// quality gate, then one upload. The cubit owns the camera it creates and
/// releases it before uploading; photos live only in memory.
class FaceRegistrationCubit extends Cubit<FaceRegistrationState> {
  FaceRegistrationCubit({
    required this.repository,
    required this.cameraFactory,
    this.replaceExisting = false,
    this.photoTarget = 5,
    this.stableFrames = 3,
    this.cooldownFrames = 6,
  }) : super(const FaceRegistrationConsent());

  final FaceRepository repository;
  final FaceCamera Function() cameraFactory;
  final bool replaceExisting;
  final int photoTarget;

  /// Consecutive passing frames before a shot, so a face passing through
  /// the oval is not captured mid-motion.
  final int stableFrames;

  /// Frames skipped after a shot, so the photos are not near-duplicates.
  final int cooldownFrames;

  final List<Uint8List> _photos = [];
  FaceCamera? _camera;
  StreamSubscription<FaceFrame>? _frames;
  int _streak = 0;
  int _cooldown = 0;
  bool _capturing = false;

  /// The running camera while capturing, for the preview.
  FaceCamera? get camera => _camera;

  void acceptConsent() => emit(const FaceRegistrationIntro());

  Future<void> begin() async {
    _photos.clear();
    _streak = 0;
    _cooldown = 0;
    // Created before the emit so the first build already has the preview.
    final camera = _camera ??= cameraFactory();
    emit(FaceRegistrationCapturing(captured: 0, total: photoTarget));
    try {
      await camera.start();
    } on FaceCameraException catch (e) {
      if (!isClosed) emit(FaceRegistrationCameraFault(e.fault));
      return;
    }
    _frames ??= camera.frames.listen(onFrame);
  }

  Future<void> onFrame(FaceFrame frame) async {
    final current = state;
    if (current is! FaceRegistrationCapturing || _capturing) return;
    final issue = faceIssue(frame);
    if (_cooldown > 0) _cooldown--;
    _streak = issue == null ? _streak + 1 : 0;
    if (issue != current.issue) {
      emit(
        FaceRegistrationCapturing(
          captured: _photos.length,
          total: photoTarget,
          issue: issue,
        ),
      );
    }
    if (issue == null && _streak >= stableFrames && _cooldown == 0) {
      await _capture();
    }
  }

  Future<void> _capture() async {
    _capturing = true;
    try {
      _photos.add(await _camera!.capture());
    } on FaceCameraException catch (e) {
      await _releaseCamera();
      if (!isClosed) emit(FaceRegistrationCameraFault(e.fault));
      return;
    } finally {
      _capturing = false;
    }
    _streak = 0;
    _cooldown = cooldownFrames;
    if (isClosed) return;
    if (_photos.length < photoTarget) {
      emit(
        FaceRegistrationCapturing(captured: _photos.length, total: photoTarget),
      );
      return;
    }
    await _releaseCamera();
    await _upload();
  }

  /// "Coba Lagi": re-sends the same photos after a network/server failure,
  /// otherwise starts a new capture.
  Future<void> retry() async {
    final current = state;
    if (current is FaceRegistrationFailed &&
        current.canResubmit &&
        _photos.isNotEmpty) {
      await _upload();
    } else {
      await begin();
    }
  }

  Future<void> _upload() async {
    final submitted = _photos.length;
    emit(FaceRegistrationUploading(submitted));
    final result = await repository.register(
      List.of(_photos),
      replaceExisting: replaceExisting,
    );
    if (isClosed) return;
    result.match((failure) => emit(_onFailure(failure, submitted)), (done) {
      _photos.clear();
      emit(
        FaceRegistrationSuccess(
          accepted: done.photoCount,
          submitted: submitted,
        ),
      );
    });
  }

  FaceRegistrationState _onFailure(Failure failure, int submitted) {
    switch (failure.errorCode) {
      case FaceErrorCodes.serviceUnavailable:
        _photos.clear();
        return const FaceRegistrationServiceUnavailable();
      case FaceErrorCodes.alreadyRegistered:
        _photos.clear();
        return FaceRegistrationSuccess(accepted: null, submitted: submitted);
    }
    final status = failure.statusCode;
    final canResubmit =
        failure is NetworkFailure ||
        status == 429 ||
        (status != null && status >= 500);
    // Rejected photos (quality, duplicate face) are useless: drop them.
    if (!canResubmit) _photos.clear();
    return FaceRegistrationFailed(
      message: failure.message,
      canResubmit: canResubmit,
    );
  }

  Future<void> _releaseCamera() async {
    final camera = _camera;
    _camera = null;
    await _frames?.cancel();
    _frames = null;
    await camera?.dispose();
  }

  @override
  Future<void> close() async {
    _photos.clear();
    await _releaseCamera();
    return await super.close();
  }
}
