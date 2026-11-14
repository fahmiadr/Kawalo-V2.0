import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Status siklus hidup formulir pelaporan insiden.
enum IncidentFormStatus {
  initial,

  /// Photos are being uploaded before the report is sent.
  uploading,
  submitting,
  success,
  failure,
}

/// State of the one-field incident report ("Apa yang terjadi?"). The text is
/// split into the API's `title`/`description` only when it is sent.
class IncidentFormState extends Equatable {
  const IncidentFormState({
    this.status = IncidentFormStatus.initial,
    this.text = '',
    this.textError,
    this.photos = const [],
    this.glat,
    this.glong,
    this.isResolvingLocation = false,
    this.locationError,
    this.errorMessage,
    this.createdIncident,
    this.validationAttempt = 0,
  });

  final IncidentFormStatus status;
  final String text;
  final String? textError;

  /// At most 4 photos.
  final List<IncidentMediaItem> photos;

  final double? glat;
  final double? glong;
  final bool isResolvingLocation;

  /// Why no location was obtained (Indonesian); the report stays sendable.
  final String? locationError;

  /// Validation, upload or network error shown above the form.
  final String? errorMessage;

  final IncidentEntity? createdIncident;

  /// Bumped on every submit attempt; the field shows its error only after the
  /// first attempt so a half-typed sentence is not flagged.
  final int validationAttempt;

  bool get isSubmitting => status == IncidentFormStatus.submitting;
  bool get isUploading => status == IncidentFormStatus.uploading;

  /// Includes a single-photo retry outside of submit.
  bool get isUploadingPhotos => photos.any((p) => p.isUploading);

  bool get isBusy => isSubmitting || isUploading || isUploadingPhotos;

  /// Latitude and longitude only count as a pair.
  bool get hasLocation => glat != null && glong != null;

  bool get isSuccess => status == IncidentFormStatus.success;

  bool get isDirty => text.trim().isNotEmpty || photos.isNotEmpty;

  bool get canPressSubmit => !isBusy;

  int get remainingPhotoSlots => 4 - photos.length;

  /// Combined upload progress of all photos, 0..1.
  double get uploadProgress {
    if (photos.isEmpty) return 0;
    final sum = photos.fold<double>(
      0,
      (acc, p) => acc + (p.isUploaded ? 1 : p.uploadProgress),
    );
    return sum / photos.length;
  }

  /// 1-based index of the photo currently being uploaded.
  int get uploadingPhotoNumber {
    final done = photos.where((p) => p.isUploaded).length;
    return (done + 1).clamp(1, photos.isEmpty ? 1 : photos.length);
  }

  IncidentFormState copyWith({
    IncidentFormStatus? status,
    String? text,
    String? Function()? textError,
    List<IncidentMediaItem>? photos,
    double? glat,
    double? glong,
    bool clearLocation = false,
    bool? isResolvingLocation,
    String? Function()? locationError,
    String? Function()? errorMessage,
    IncidentEntity? createdIncident,
    int? validationAttempt,
  }) {
    return IncidentFormState(
      status: status ?? this.status,
      text: text ?? this.text,
      textError: textError != null ? textError() : this.textError,
      photos: photos ?? this.photos,
      glat: clearLocation ? null : glat ?? this.glat,
      glong: clearLocation ? null : glong ?? this.glong,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      locationError: locationError != null
          ? locationError()
          : this.locationError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      createdIncident: createdIncident ?? this.createdIncident,
      validationAttempt: validationAttempt ?? this.validationAttempt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    text,
    textError,
    photos,
    glat,
    glong,
    isResolvingLocation,
    locationError,
    errorMessage,
    createdIncident,
    validationAttempt,
  ];
}
