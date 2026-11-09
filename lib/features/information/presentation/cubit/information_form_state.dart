import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Status proses pengiriman / penyimpanan formulir informasi.
enum InformationFormStatus {
  /// Status awal saat formulir dimuat.
  initial,

  /// Formulir siap untuk diedit atau diisi pengguna.
  ready,

  /// Formulir sedang dikirim ke server backend.
  submitting,

  /// Formulir berhasil dipublikasikan / diperbarui.
  success,

  /// Terjadi kegagalan saat pengiriman formulir.
  failure,
}

/// Mode operasi formulir informasi.
enum InformationFormMode {
  /// Mode penambahan postingan / feed baru (Create).
  create,

  /// Mode pembaruan postingan / feed yang sudah ada (Update/Edit).
  update,
}

/// State untuk formulir publikasi dan pembaruan data informasi
/// (`InformationFormCubit`).
class InformationFormState extends Equatable {
  /// Membuat instance [InformationFormState].
  const InformationFormState({
    this.mode = InformationFormMode.create,
    this.status = InformationFormStatus.initial,
    this.initialItem,
    this.title = '',
    this.titleError,
    this.text = '',
    this.textError,
    this.feedType = 'GENERAL',
    this.feedTypeError,
    this.photos = const <InformationFormMediaItem>[],
    this.photosError,
    this.documentMedia,
    this.feedFile = '',
    this.feedFileError,
    this.eventLocation = '',
    this.eventLocationError,
    this.glat = '',
    this.glatError,
    this.glong = '',
    this.glongError,
    this.errorMessage,
    this.createdOrUpdatedItem,
    this.validationAttempt = 0,
    this.isResolvingLocation = false,
    this.gpsResult,
    this.gpsResultVersion = 0,
  });

  /// Mode operasi formulir (create / update).
  final InformationFormMode mode;

  /// Status siklus proses formulir.
  final InformationFormStatus status;

  /// Entitas asli jika berada dalam mode pembaruan
  /// ([InformationFormMode.update]).
  final InformationItemEntity? initialItem;

  /// Judul informasi (FeedTitle) - wajib, max 128 karakter.
  final String title;

  /// Pesan error validasi untuk [title].
  final String? titleError;

  /// Deskripsi isi informasi lengkap (FeedText) - opsional, max 1024 karakter.
  final String text;

  /// Pesan error validasi untuk [text].
  final String? textError;

  /// Tipe kategori informasi (GENERAL, INCIDENT, JOIN, EVENT, OTHER).
  final String feedType;

  /// Pesan error validasi untuk [feedType].
  final String? feedTypeError;

  /// Daftar media foto yang dilampirkan (maksimal 4 foto berurutan).
  final List<InformationFormMediaItem> photos;

  /// Pesan error validasi untuk [photos].
  final String? photosError;

  /// Item dokumen lokal atau remote yang dilampirkan (maksimal 1 berkas).
  final InformationFormMediaItem? documentMedia;

  /// Berkas lampiran feed berupa string tautan / path dokumen.
  final String feedFile;

  /// Pesan error validasi untuk [feedFile].
  final String? feedFileError;

  /// Lokasi acara atau tempat kejadian (opsional, max 128 karakter).
  final String eventLocation;

  /// Pesan error validasi untuk [eventLocation].
  final String? eventLocationError;

  /// Garis lintang GPS (opsional, max 32 karakter).
  final String glat;

  /// Pesan error validasi untuk [glat].
  final String? glatError;

  /// Garis bujur GPS (opsional, max 32 karakter).
  final String glong;

  /// Pesan error validasi untuk [glong].
  final String? glongError;

  /// Pesan kegagalan dari server backend atau usecase.
  final String? errorMessage;

  /// Entitas informasi yang berhasil dibuat atau diperbarui.
  final InformationItemEntity? createdOrUpdatedItem;

  /// Penghitung percobaan validasi submit untuk memicu auto-focus
  /// ke field pertama yang bermasalah pada lapisan UI.
  final int validationAttempt;

  final bool isResolvingLocation;

  /// Latest GPS lookup outcome. Equal results (e.g. two timeouts in a row)
  /// compare equal, so listeners must key on [gpsResultVersion] instead.
  final LocationResult? gpsResult;

  /// Incremented on every delivered GPS outcome so listeners fire even
  /// when [gpsResult] is equal to the previous one.
  final int gpsResultVersion;

  /// Batas kuota maksimal foto dokumentasi yang diizinkan pada formulir.
  static const int maxPhotosLimit = 4;

  /// Jumlah sisa slot foto dokumentasi yang masih dapat dilampirkan.
  int get remainingPhotoSlots =>
      (maxPhotosLimit - photos.length).clamp(0, maxPhotosLimit);

  /// Menandakan apakah kuota foto dokumentasi telah mencapai batas maksimum.
  bool get isPhotoLimitReached => photos.length >= maxPhotosLimit;

  /// Menandakan apakah sedang dalam mode pembuatan postingan baru.
  bool get isCreateMode => mode == InformationFormMode.create;

  /// Menandakan apakah sedang dalam mode pembaruan / edit informasi.
  bool get isUpdateMode => mode == InformationFormMode.update;

  /// Menandakan apakah formulir sedang dalam proses pengiriman ke server.
  bool get isSubmitting => status == InformationFormStatus.submitting;

  /// Garis lintang dalam bentuk numerik jika valid.
  double? get latitude => double.tryParse(glat.trim());

  /// Garis bujur dalam bentuk numerik jika valid.
  double? get longitude => double.tryParse(glong.trim());

  /// Menandakan apakah titik lokasi GPS terpasang secara valid.
  bool get hasLocation => latitude != null && longitude != null;

  /// Menandakan apakah formulir memiliki perubahan dibandingkan nilai awal.
  bool get isDirty {
    if (isCreateMode) {
      return title.trim().isNotEmpty ||
          text.trim().isNotEmpty ||
          photos.isNotEmpty ||
          documentMedia != null ||
          feedFile.trim().isNotEmpty ||
          eventLocation.trim().isNotEmpty ||
          glat.trim().isNotEmpty ||
          glong.trim().isNotEmpty ||
          feedType != 'GENERAL';
    }

    final original = initialItem;
    if (original == null) return false;

    final origTitle = original.title ?? '';
    final origText = original.text ?? '';
    final origFeedType = original.feedType ?? 'GENERAL';
    final origFeedFile = original.feedFile ?? '';
    final origLocation = original.eventLocation ?? '';
    final origGlat = original.glat != null ? original.glat.toString() : '';
    final origGlong = original.glong != null ? original.glong.toString() : '';

    final currentSources = photos
        .map((p) => p.remoteUrl ?? p.displaySource)
        .toList();

    return title.trim() != origTitle.trim() ||
        text.trim() != origText.trim() ||
        feedType != origFeedType ||
        feedFile.trim() != origFeedFile.trim() ||
        eventLocation.trim() != origLocation.trim() ||
        glat.trim() != origGlat.trim() ||
        glong.trim() != origGlong.trim() ||
        !listEquals(currentSources, original.photos);
  }

  /// Menandakan apakah seluruh isian valid secara logika input domain.
  bool get isValid {
    final titleTrimmed = title.trim();
    if (titleTrimmed.isEmpty || titleTrimmed.length > 128) {
      return false;
    }
    if (titleError != null) return false;
    if (text.length > 1024 || textError != null) return false;
    if (feedFile.length > 2048 || feedFileError != null) return false;
    if (eventLocation.length > 128 || eventLocationError != null) return false;
    if (photos.length > 4 || photosError != null) return false;
    if (glatError != null || glongError != null) return false;
    final hasGlat = glat.trim().isNotEmpty;
    final hasGlong = glong.trim().isNotEmpty;
    if (hasGlat != hasGlong) return false;
    if (!InformationFeedType.allowedCodes.contains(feedType.toUpperCase())) {
      return false;
    }
    return true;
  }

  /// Menandakan apakah tombol aksi (Posting/Simpan) dapat ditekan pengguna:
  /// - Tidak sedang dalam proses pengiriman (`!isSubmitting`).
  /// - Tidak ada berkas media foto yang masih dalam proses pemrosesan/unggah.
  /// - Pada mode pembaruan (edit): wajib memiliki perubahan data (`isDirty`).
  bool get canPressSubmit {
    if (isSubmitting) return false;
    if (photos.any((p) => p.isLoading)) return false;
    if (isUpdateMode && !isDirty) return false;
    return true;
  }

  /// Menandakan apakah formulir memenuhi seluruh syarat untuk dikirim:
  /// - Memenuhi syarat penekanan tombol submit (`canPressSubmit`).
  /// - Seluruh input valid sesuai aturan bisnis domain (`isValid`).
  bool get canSubmit => canPressSubmit && isValid;

  /// Menyalin state dengan nilai-nilai baru secara immutable.
  InformationFormState copyWith({
    InformationFormMode? mode,
    InformationFormStatus? status,
    InformationItemEntity? initialItem,
    String? title,
    ValueGetter<String?>? titleError,
    String? text,
    ValueGetter<String?>? textError,
    String? feedType,
    ValueGetter<String?>? feedTypeError,
    List<InformationFormMediaItem>? photos,
    ValueGetter<String?>? photosError,
    ValueGetter<InformationFormMediaItem?>? documentMedia,
    String? feedFile,
    ValueGetter<String?>? feedFileError,
    String? eventLocation,
    ValueGetter<String?>? eventLocationError,
    String? glat,
    ValueGetter<String?>? glatError,
    String? glong,
    ValueGetter<String?>? glongError,
    ValueGetter<String?>? errorMessage,
    InformationItemEntity? createdOrUpdatedItem,
    int? validationAttempt,
    bool? isResolvingLocation,
    LocationResult? gpsResult,
    int? gpsResultVersion,
  }) {
    return InformationFormState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      initialItem: initialItem ?? this.initialItem,
      title: title ?? this.title,
      titleError: titleError != null ? titleError() : this.titleError,
      text: text ?? this.text,
      textError: textError != null ? textError() : this.textError,
      feedType: feedType ?? this.feedType,
      feedTypeError: feedTypeError != null
          ? feedTypeError()
          : this.feedTypeError,
      photos: photos ?? this.photos,
      photosError: photosError != null ? photosError() : this.photosError,
      documentMedia: documentMedia != null
          ? documentMedia()
          : this.documentMedia,
      feedFile: feedFile ?? this.feedFile,
      feedFileError: feedFileError != null
          ? feedFileError()
          : this.feedFileError,
      eventLocation: eventLocation ?? this.eventLocation,
      eventLocationError: eventLocationError != null
          ? eventLocationError()
          : this.eventLocationError,
      glat: glat ?? this.glat,
      glatError: glatError != null ? glatError() : this.glatError,
      glong: glong ?? this.glong,
      glongError: glongError != null ? glongError() : this.glongError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      createdOrUpdatedItem: createdOrUpdatedItem ?? this.createdOrUpdatedItem,
      validationAttempt: validationAttempt ?? this.validationAttempt,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      gpsResult: gpsResult ?? this.gpsResult,
      gpsResultVersion: gpsResultVersion ?? this.gpsResultVersion,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    status,
    initialItem,
    title,
    titleError,
    text,
    textError,
    feedType,
    feedTypeError,
    photos,
    photosError,
    documentMedia,
    feedFile,
    feedFileError,
    eventLocation,
    eventLocationError,
    glat,
    glatError,
    glong,
    glongError,
    errorMessage,
    createdOrUpdatedItem,
    validationAttempt,
    isResolvingLocation,
    gpsResult,
    gpsResultVersion,
  ];
}
