import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_location_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';

enum AttendanceLocationPhase { loading, loaded, failure }

class AttendanceLocationState extends Equatable {
  const AttendanceLocationState({
    this.phase = AttendanceLocationPhase.loading,
    this.location,
    this.latitude,
    this.longitude,
    this.locationName = '',
    this.radiusText = '${AttendanceLocationCubit.defaultRadius}',
    this.isCustomRadius = false,
    this.saving = false,
    this.errorMessage,
    this.notice,
    this.noticeSeq = 0,
  });

  final AttendanceLocationPhase phase;

  /// Last value known to the server.
  final AttendanceLocationEntity? location;

  /// Draft values; they differ from [location] until saved.
  final double? latitude;
  final double? longitude;
  final String locationName;

  /// Kept as text so a half-typed custom radius survives rebuilds.
  final String radiusText;
  final bool isCustomRadius;
  final bool saving;
  final String? errorMessage;

  /// One-shot message for a snackbar; [noticeSeq] makes repeats distinct.
  final String? notice;
  final int noticeSeq;

  bool get isLoaded => phase == AttendanceLocationPhase.loaded;

  bool get hasPoint => latitude != null && longitude != null;

  int? get radius => int.tryParse(radiusText.trim());

  bool get isRadiusValid {
    final r = radius;
    final loc = location;
    return r != null && loc != null && r >= loc.minRadius && r <= loc.maxRadius;
  }

  /// Shown under the custom radius field.
  String? get radiusError {
    final loc = location;
    if (loc == null || isRadiusValid) return null;
    return 'Radius harus ${loc.minRadius} sampai ${loc.maxRadius} meter.';
  }

  bool get isValid =>
      hasPoint &&
      !(latitude == 0 && longitude == 0) &&
      isRadiusValid &&
      locationName.trim().length <= AttendanceLocationCubit.nameMax;

  bool get isDirty {
    final loc = location;
    if (loc == null || !isLoaded) return false;
    if (!loc.configured) return hasPoint;
    return latitude != loc.latitude ||
        longitude != loc.longitude ||
        locationName.trim() != (loc.locationName ?? '') ||
        radius != loc.radius;
  }

  bool get canSave => isLoaded && !saving && isValid && isDirty;

  AttendanceLocationState copyWith({
    AttendanceLocationPhase? phase,
    AttendanceLocationEntity? location,
    double? latitude,
    double? longitude,
    String? locationName,
    String? radiusText,
    bool? isCustomRadius,
    bool? saving,
    String? notice,
  }) => AttendanceLocationState(
    phase: phase ?? this.phase,
    location: location ?? this.location,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    locationName: locationName ?? this.locationName,
    radiusText: radiusText ?? this.radiusText,
    isCustomRadius: isCustomRadius ?? this.isCustomRadius,
    saving: saving ?? this.saving,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    phase,
    location,
    latitude,
    longitude,
    locationName,
    radiusText,
    isCustomRadius,
    saving,
    errorMessage,
    notice,
    noticeSeq,
  ];
}

/// Loads and edits the group's single attendance point (admin only).
class AttendanceLocationCubit extends Cubit<AttendanceLocationState> {
  AttendanceLocationCubit({required this.repository})
    : super(const AttendanceLocationState());

  static const String savedMessage = 'Titik absen disimpan';

  /// Radius chips offered next to "Lainnya", in metres.
  static const radiusPresets = [25, 50, 100, 200, 500, 1000];
  static const defaultRadius = 100;
  static const nameMax = 128;

  final AttendanceAdminRepository repository;

  static AttendanceLocationState _loaded(
    AttendanceLocationEntity location, {
    String? notice,
    int noticeSeq = 0,
  }) {
    final radius = location.radius ?? defaultRadius;
    return AttendanceLocationState(
      phase: AttendanceLocationPhase.loaded,
      location: location,
      latitude: location.latitude,
      longitude: location.longitude,
      locationName: location.locationName ?? '',
      radiusText: '$radius',
      isCustomRadius: !radiusPresets.contains(radius),
      notice: notice,
      noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
    );
  }

  Future<void> load() async {
    emit(const AttendanceLocationState());
    final result = await repository.getLocation();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        AttendanceLocationState(
          phase: AttendanceLocationPhase.failure,
          errorMessage: failure.message,
        ),
      ),
      (location) => emit(_loaded(location)),
    );
  }

  bool get _editable => state.isLoaded && !state.saving;

  void setCoordinates(double latitude, double longitude) {
    if (!_editable) return;
    emit(state.copyWith(latitude: latitude, longitude: longitude));
  }

  void setLocationName(String value) {
    if (!_editable) return;
    emit(state.copyWith(locationName: value));
  }

  void selectRadiusPreset(int metres) {
    if (!_editable) return;
    emit(state.copyWith(radiusText: '$metres', isCustomRadius: false));
  }

  void selectCustomRadius() {
    if (!_editable) return;
    emit(state.copyWith(isCustomRadius: true));
  }

  void setRadiusText(String value) {
    if (!_editable) return;
    emit(state.copyWith(radiusText: value));
  }

  Future<void> save() async {
    if (!state.canSave) return;
    final snapshot = state;
    emit(state.copyWith(saving: true));
    final result = await repository.saveLocation(
      latitude: snapshot.latitude!,
      longitude: snapshot.longitude!,
      radius: snapshot.radius!,
      locationName: snapshot.locationName,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(saving: false, notice: failure.message)),
      (location) => emit(
        _loaded(location, notice: savedMessage, noticeSeq: state.noticeSeq),
      ),
    );
  }
}
