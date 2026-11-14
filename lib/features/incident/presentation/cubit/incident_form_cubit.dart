import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/create_incident/create_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/create_incident/create_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_photo_uploader.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Cubit yang mengelola state formulir pelaporan insiden baru, validasi,
/// dan pengiriman ke API.
class IncidentFormCubit extends Cubit<IncidentFormState> {
  /// Membuat instance [IncidentFormCubit].
  IncidentFormCubit({
    required this.createIncidentUseCase,
    required UploadRepository uploadRepository,
    LocationService locationService = const DefaultLocationService(),
  }) : _uploader = IncidentPhotoUploader(uploadRepository),
       _locationService = locationService,
       super(const IncidentFormState());

  /// Use case untuk membuat laporan insiden.
  final CreateIncidentUseCase createIncidentUseCase;

  final IncidentPhotoUploader _uploader;
  final LocationService _locationService;
  int _locationGeneration = 0;

  AppCancellationToken? _submitCancelToken;

  @override
  Future<void> close() {
    _submitCancelToken?.cancel('cubit_closed');
    return super.close();
  }

  IncidentFormStatus _statusOnInput() {
    return state.status == IncidentFormStatus.failure
        ? IncidentFormStatus.initial
        : state.status;
  }

  /// The API caps `title` at 128 characters.
  static const titleMaxLength = 128;

  /// Caps the whole text so it always fits the API `description` (1024).
  static const textMaxLength = 1000;

  static const textMinLength = 5;

  static String? validateText(String value) {
    final trimmed = value.trim();
    if (trimmed.length < textMinLength) {
      return 'Tulis apa yang terjadi, minimal $textMinLength karakter.';
    }
    if (trimmed.length > textMaxLength) {
      return 'Maksimal $textMaxLength karakter.';
    }
    return null;
  }

  /// Splits the report into the API's `title` and `description`: the first
  /// sentence (up to the first `.`, `!`, `?` or newline) is the title and the
  /// rest the description, null when empty. A first sentence longer than
  /// [titleMaxLength] is cut, and then the whole text goes to the
  /// description so nothing the guard wrote is lost.
  static ({String title, String? description}) splitReport(String text) {
    final trimmed = text.trim();
    final end = trimmed.indexOf(RegExp(r'[.!?\n]'));
    var title = (end < 0 ? trimmed : trimmed.substring(0, end)).trim();
    // "Rusak..." or "Rusak?!" must not leave "..", "!" as the description.
    var rest = end < 0
        ? ''
        : trimmed.substring(end + 1).replaceFirst(RegExp(r'^[.!?\s]+'), '');
    rest = rest.trim();
    if (title.isEmpty) {
      // Text starting with punctuation: fall back to the whole text.
      title = trimmed;
      rest = '';
    }
    if (title.length > titleMaxLength) {
      return (
        title: '${title.substring(0, titleMaxLength - 1).trimRight()}…',
        description: trimmed,
      );
    }
    return (title: title, description: rest.isEmpty ? null : rest);
  }

  void updateText(String text) {
    emit(
      state.copyWith(
        text: text,
        textError: () =>
            state.validationAttempt > 0 ? validateText(text) : null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menambahkan foto lampiran baru (maksimal 4).
  void addPhoto(IncidentMediaItem photo) {
    if (state.photos.length >= 4) return;
    emit(
      state.copyWith(
        photos: [...state.photos, photo],
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menambahkan sekumpulan foto lampiran baru (maksimal 4 total).
  void addPhotos(List<IncidentMediaItem> newPhotos) {
    final availableSlots = 4 - state.photos.length;
    if (availableSlots <= 0) return;

    final photosToAdd = newPhotos.take(availableSlots).toList();
    emit(
      state.copyWith(
        photos: [...state.photos, ...photosToAdd],
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menghapus foto lampiran berdasarkan ID.
  void removePhoto(String photoId) {
    emit(
      state.copyWith(
        photos: state.photos.where((p) => p.id != photoId).toList(),
        status: _statusOnInput(),
      ),
    );
  }

  /// Menghapus seluruh foto lampiran dari formulir.
  void clearPhotos() {
    emit(
      state.copyWith(
        photos: const [],
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Mengatur ulang posisi urutan foto lampiran (misal: jadikan utama, geser
  /// kiri/kanan).
  void reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.photos.length) return;
    if (newIndex < 0 || newIndex >= state.photos.length) return;
    if (oldIndex == newIndex) return;

    final updated = List<IncidentMediaItem>.from(state.photos);
    final movedItem = updated.removeAt(oldIndex);
    updated.insert(newIndex, movedItem);

    emit(
      state.copyWith(
        photos: updated,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui koordinat lokasi GPS insiden. Lintang dan bujur harus
  /// berpasangan; hanya salah satu berarti tidak ada lokasi.
  void updateLocation({double? lat, double? long}) {
    if (lat == null || long == null) {
      emit(state.copyWith(clearLocation: true));
      return;
    }
    emit(state.copyWith(glat: lat, glong: long, locationError: () => null));
  }

  /// Menghapus lokasi dari laporan.
  void clearLocation() {
    _locationGeneration++;
    emit(
      state.copyWith(
        clearLocation: true,
        isResolvingLocation: false,
        locationError: () => null,
      ),
    );
  }

  /// Resolves the device GPS position into [IncidentFormState.glat]/`glong`.
  /// On failure the report stays sendable without a location and
  /// [IncidentFormState.locationError] explains why.
  ///
  /// [fetchPosition] overrides the injected [LocationService] (test seam).
  Future<void> resolveLocation({
    Future<LocationResult> Function()? fetchPosition,
  }) async {
    if (state.isResolvingLocation) return;
    final generation = ++_locationGeneration;
    emit(state.copyWith(isResolvingLocation: true, locationError: () => null));

    LocationResult result;
    try {
      result = await (fetchPosition ?? _locationService.getCurrentPosition)();
    } on Object catch (_) {
      result = const LocationResult.error('Lokasi tidak dapat diperoleh.');
    }
    // A clearLocation() call made meanwhile supersedes this lookup.
    if (isClosed || generation != _locationGeneration) return;

    final coordinates = result.isSuccess ? result.coordinates : null;
    if (coordinates == null) {
      emit(
        state.copyWith(
          clearLocation: true,
          isResolvingLocation: false,
          locationError: () =>
              result.errorMessage ?? 'Lokasi tidak dapat diperoleh.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        glat: coordinates.$1,
        glong: coordinates.$2,
        isResolvingLocation: false,
        locationError: () => null,
      ),
    );
  }

  void _patchPhoto(
    String id,
    IncidentMediaItem Function(IncidentMediaItem current) change,
  ) {
    if (isClosed) return;
    emit(
      state.copyWith(
        photos: [
          for (final p in state.photos)
            if (p.id == id) change(p) else p,
        ],
      ),
    );
  }

  /// Retries the upload of a single failed photo.
  Future<void> retryPhotoUpload(String photoId) async {
    if (state.isBusy) return;
    final photo = state.photos.where((p) => p.id == photoId).firstOrNull;
    if (photo == null || !photo.needsUpload) return;
    await _uploader.upload([photo], _patchPhoto);
  }

  /// Mengirimkan formulir pembuatan laporan insiden baru ke server.
  Future<void> submit({required AuthSessionEntity? session}) async {
    if (state.isBusy) return;

    final textErr = validateText(state.text);
    if (textErr != null) {
      emit(
        state.copyWith(
          textError: () => textErr,
          validationAttempt: state.validationAttempt + 1,
        ),
      );
      return;
    }

    final groupId = session?.groupUid;
    if (groupId == null || groupId.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () =>
              'Grup pengguna tidak ditemukan. Pastikan akun terdaftar di grup '
              'aktif.',
          validationAttempt: state.validationAttempt + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: IncidentFormStatus.uploading,
        errorMessage: () => null,
        validationAttempt: state.validationAttempt + 1,
      ),
    );

    await _uploader.upload(state.photos, _patchPhoto);
    if (isClosed) return;

    // Only uploaded URLs may reach the payload; a local file must never leak.
    final failed = [
      for (var i = 0; i < state.photos.length; i++)
        if (!state.photos[i].isUploaded) i + 1,
    ];
    if (failed.isNotEmpty) {
      emit(
        state.copyWith(
          status: IncidentFormStatus.failure,
          errorMessage: () => failed.length == 1
              ? 'Foto ke-${failed.single} gagal diunggah. Laporan belum '
                    'terkirim.'
              : '${failed.length} foto gagal diunggah. Laporan belum '
                    'terkirim.',
        ),
      );
      return;
    }

    _submitCancelToken?.cancel('resubmitted');
    final cancelToken = DioCancellationToken();
    _submitCancelToken = cancelToken;

    emit(state.copyWith(status: IncidentFormStatus.submitting));

    final photoUrls = state.photos.map((p) => p.remoteUrl!).toList();

    final report = splitReport(state.text);
    // No category: the field is no longer shown and the API applies its own
    // default.
    final params = CreateIncidentParams(
      title: report.title,
      groupId: groupId,
      description: report.description,
      glat: state.hasLocation ? state.glat : null,
      glong: state.hasLocation ? state.glong : null,
      photos: photoUrls,
      session: session,
      cancelToken: cancelToken,
    );

    final result = await createIncidentUseCase(params);

    if (isClosed) return;

    result.fold(
      (failure) {
        if (failure is RequestCancelledFailure) return;
        emit(
          state.copyWith(
            status: IncidentFormStatus.failure,
            errorMessage: () => failure.message,
          ),
        );
      },
      (created) {
        emit(
          state.copyWith(
            status: IncidentFormStatus.success,
            createdIncident: created,
            errorMessage: () => null,
          ),
        );
      },
    );
  }
}
