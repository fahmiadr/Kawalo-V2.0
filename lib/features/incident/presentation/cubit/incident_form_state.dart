import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';
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

/// State representasi layar formulir pembuatan laporan insiden baru.
class IncidentFormState extends Equatable {
  /// Membuat instance [IncidentFormState].
  const IncidentFormState({
    this.status = IncidentFormStatus.initial,
    this.title = '',
    this.titleError,
    this.description = '',
    this.descriptionError,
    this.category = IncidentCategory.general,
    this.photos = const [],
    this.glat,
    this.glong,
    this.isResolvingLocation = false,
    this.locationError,
    this.errorMessage,
    this.createdIncident,
    this.validationAttempt = 0,
  });

  /// Status pengiriman formulir.
  final IncidentFormStatus status;

  /// Judul insiden.
  final String title;

  /// Pesan error validasi untuk [title].
  final String? titleError;

  /// Deskripsi peristiwa insiden.
  final String description;

  /// Pesan error validasi untuk [description].
  final String? descriptionError;

  /// Kategori insiden.
  final IncidentCategory category;

  /// Daftar foto lampiran bukti (maksimal 4).
  final List<IncidentMediaItem> photos;

  /// Titik garis lintang GPS.
  final double? glat;

  /// Titik garis bujur GPS.
  final double? glong;

  /// Apakah GPS sedang dicari.
  final bool isResolvingLocation;

  /// Alasan lokasi tidak diperoleh (Bahasa Indonesia); laporan tetap bisa
  /// dikirim tanpa lokasi.
  final String? locationError;

  /// Pesan kesalahan validasi atau jaringan.
  final String? errorMessage;

  /// Entitas insiden yang berhasil dibuat (disimpan saat status success).
  final IncidentEntity? createdIncident;

  /// Jumlah percobaan pengiriman form untuk kalkulasi penampakan error.
  final int validationAttempt;

  /// Apakah form sedang dalam proses pengiriman ke server.
  bool get isSubmitting => status == IncidentFormStatus.submitting;

  /// Apakah foto sedang diunggah sebelum laporan dikirim.
  bool get isUploading => status == IncidentFormStatus.uploading;

  /// Apakah ada foto yang sedang diunggah (termasuk coba-ulang per foto).
  bool get isUploadingPhotos => photos.any((p) => p.isUploading);

  /// Apakah form sedang sibuk mengunggah atau mengirim; mengunci foto.
  bool get isBusy => isSubmitting || isUploading || isUploadingPhotos;

  /// Apakah koordinat lengkap (lintang dan bujur harus berpasangan).
  bool get hasLocation => glat != null && glong != null;

  /// Apakah formulir berhasil dikirimkan ke server.
  bool get isSuccess => status == IncidentFormStatus.success;

  /// Apakah pengguna telah mengisikan atau memodifikasi data form.
  bool get isDirty =>
      title.trim().isNotEmpty ||
      description.trim().isNotEmpty ||
      photos.isNotEmpty;

  /// Menandakan apakah tombol aksi 'Kirim' dapat ditekan pengguna.
  bool get canPressSubmit => !isBusy;

  /// Mengembalikan nama field pertama yang melanggar validasi agar
  /// lapisan antarmuka UI dapat secara otomatis memfokuskan keyboard ke sana.
  String? get firstInvalidField {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || title.length > 128 || titleError != null) {
      return 'title';
    }
    if (description.length > 1000 || descriptionError != null) {
      return 'description';
    }
    return null;
  }

  /// Menandakan apakah seluruh isian valid secara logika bisnis.
  bool get isValid =>
      title.trim().isNotEmpty &&
      title.length <= 128 &&
      titleError == null &&
      description.length <= 1000 &&
      descriptionError == null;

  /// Jumlah sisa slot foto yang dapat ditambahkan (maksimal 4).
  int get remainingPhotoSlots => 4 - photos.length;

  /// Membuat duplikasi state dengan properti baru.
  IncidentFormState copyWith({
    IncidentFormStatus? status,
    String? title,
    String? Function()? titleError,
    String? description,
    String? Function()? descriptionError,
    IncidentCategory? category,
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
      title: title ?? this.title,
      titleError: titleError != null ? titleError() : this.titleError,
      description: description ?? this.description,
      descriptionError: descriptionError != null
          ? descriptionError()
          : this.descriptionError,
      category: category ?? this.category,
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
    title,
    titleError,
    description,
    descriptionError,
    category,
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
