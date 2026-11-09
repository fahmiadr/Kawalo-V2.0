import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/utils/trimmed_or_null.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_photos.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_validators.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Cubit pengelola alur logika bisnis dan validasi formulir publikasi
/// dan pembaruan data informasi (Create & Update).
class InformationFormCubit extends Cubit<InformationFormState> {
  /// Membuat instance [InformationFormCubit].
  InformationFormCubit({
    required this.createInformationUseCase,
    required this.updateInformationUseCase,
    LocationService locationService = const DefaultLocationService(),
    InformationItemEntity? initialItem,
  }) : _locationService = locationService,
       super(InformationFormState.initial(initialItem));

  /// Use case untuk mempublikasikan feed informasi baru.
  final CreateInformationUseCase createInformationUseCase;

  /// Use case untuk memperbarui feed informasi yang sudah ada.
  final UpdateInformationUseCase updateInformationUseCase;

  final LocationService _locationService;

  AppCancellationToken? _submitCancelToken;
  int _gpsGeneration = 0;

  @override
  Future<void> close() {
    _submitCancelToken?.cancel('cubit_closed');
    return super.close();
  }

  InformationFormStatus _statusOnInput() {
    return state.status == InformationFormStatus.failure
        ? InformationFormStatus.ready
        : state.status;
  }

  void _emitInput(InformationFormState next) {
    emit(next.copyWith(errorMessage: () => null, status: _statusOnInput()));
  }

  /// Memperbarui nilai judul postingan.
  void onTitleChanged(String value) {
    _emitInput(
      state.copyWith(
        title: value,
        titleError: () => state.titleError != null
            ? InformationFormValidators.validateTitle(value)
            : null,
      ),
    );
  }

  /// Memperbarui isi / deskripsi teks postingan.
  void onTextChanged(String value) {
    _emitInput(
      state.copyWith(
        text: value,
        textError: () => state.textError != null
            ? InformationFormValidators.validateText(value)
            : null,
      ),
    );
  }

  /// Memperbarui kategori tipe postingan
  /// (GENERAL, INCIDENT, JOIN, EVENT, OTHER).
  void onFeedTypeChanged(String value) {
    final upper = value.trim().toUpperCase();
    _emitInput(
      state.copyWith(
        feedType: upper,
        feedTypeError: () => InformationFormValidators.validateFeedType(upper),
      ),
    );
  }

  /// Memperbarui berkas lampiran feed (URL / text).
  void onFeedFileChanged(String value) {
    _emitInput(
      state.copyWith(
        feedFile: value,
        feedFileError: () => InformationFormValidators.validateFeedFile(value),
      ),
    );
  }

  /// Memperbarui lokasi kegiatan atau tempat kejadian.
  void onEventLocationChanged(String value) {
    _emitInput(
      state.copyWith(
        eventLocation: value,
        eventLocationError: () => state.eventLocationError != null
            ? InformationFormValidators.validateEventLocation(value)
            : null,
      ),
    );
  }

  /// Memperbarui koordinat garis lintang GPS (GLat).
  void onGlatChanged(String value) {
    _emitInput(
      state.copyWith(
        glat: value,
        glatError: () => InformationFormValidators.validateGlat(value),
      ),
    );
  }

  /// Memperbarui koordinat garis bujur GPS (GLong).
  void onGlongChanged(String value) {
    _emitInput(
      state.copyWith(
        glong: value,
        glongError: () => InformationFormValidators.validateGlong(value),
      ),
    );
  }

  /// Memasang titik koordinat lokasi secara terprogram dari GPS
  /// atau pemilih peta.
  void onSetLocationCoordinates({required double lat, required double lng}) {
    _emitInput(
      state.copyWith(
        glat: lat.toString(),
        glong: lng.toString(),
        glatError: () => null,
        glongError: () => null,
      ),
    );
  }

  /// Resolves the device GPS position into the form coordinates and publishes
  /// the outcome through [InformationFormState.gpsResult].
  ///
  /// [fetchPosition] overrides the injected [LocationService] (test seam).
  /// A call made while a lookup is in flight is ignored.
  Future<void> resolveGpsLocation({
    Future<LocationResult> Function()? fetchPosition,
  }) async {
    if (state.isResolvingLocation) return;
    final generation = ++_gpsGeneration;
    emit(state.copyWith(isResolvingLocation: true));

    final LocationResult result;
    try {
      result = await (fetchPosition ?? _locationService.getCurrentPosition)();
    } finally {
      if (!isClosed && generation == _gpsGeneration) {
        emit(state.copyWith(isResolvingLocation: false));
      }
    }

    if (isClosed || generation != _gpsGeneration) return;

    final coordinates = result.coordinates;
    if (result.isSuccess && coordinates != null) {
      onSetLocationCoordinates(lat: coordinates.$1, lng: coordinates.$2);
    }
    emit(
      state.copyWith(
        gpsResult: result,
        gpsResultVersion: state.gpsResultVersion + 1,
      ),
    );
  }

  /// Menghapus rekaman titik lokasi koordinat GPS dari form.
  void onClearLocationCoordinates() {
    _emitInput(
      state.copyWith(
        glat: '',
        glong: '',
        glatError: () => null,
        glongError: () => null,
      ),
    );
  }

  void _emitPhotos(
    List<InformationFormMediaItem> photos, {
    bool clearErrorMessage = true,
  }) {
    emit(
      state.copyWith(
        photos: photos,
        photosError: () => null,
        errorMessage: clearErrorMessage ? () => null : null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menambahkan media foto ([InformationFormMediaItem]) ke daftar lampiran.
  bool onAddMediaPhoto(InformationFormMediaItem item) {
    return onAddMediaPhotos([item]) > 0;
  }

  /// Menambahkan sejumlah media foto ([InformationFormMediaItem]) secara batch
  /// ke daftar lampiran hingga batas maksimal
  /// [InformationFormState.maxPhotosLimit] foto.
  ///
  /// Mengembalikan jumlah foto yang berhasil ditambahkan.
  int onAddMediaPhotos(List<InformationFormMediaItem> items) {
    if (items.isEmpty) return 0;

    final plan = InformationFormPhotos.planAdd(
      state.photos,
      items,
      maxPhotos: InformationFormState.maxPhotosLimit,
    );
    final error = plan.error;
    if (error != null) {
      emit(state.copyWith(photosError: () => error));
      return 0;
    }

    _emitPhotos([...state.photos, ...plan.added]);
    return plan.added.length;
  }

  /// Mengganti item foto tertentu berdasarkan [targetId] dengan [newItem].
  bool onReplacePhoto({
    required String targetId,
    required InformationFormMediaItem newItem,
  }) {
    final updated = InformationFormPhotos.replaceById(
      state.photos,
      targetId,
      newItem,
    );
    if (updated == null) return false;
    _emitPhotos(updated);
    return true;
  }

  /// Menghapus foto dari daftar lampiran berdasarkan [id].
  bool onRemovePhotoById(String id) {
    final index = state.photos.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    onRemovePhoto(index);
    return true;
  }

  /// Menambahkan tautan foto ke daftar lampiran foto (kompatibilitas string).
  bool onAddPhoto(String photoUrl) {
    final trimmed = photoUrl.trim();
    if (trimmed.isEmpty) return false;
    return onAddMediaPhoto(InformationFormMediaItem.fromRemoteUrl(trimmed));
  }

  /// Menghapus foto dari daftar lampiran berdasarkan [index].
  void onRemovePhoto(int index) {
    final updated = InformationFormPhotos.removeAt(state.photos, index);
    if (updated != null) _emitPhotos(updated);
  }

  /// Menghapus seluruh foto yang dilampirkan sekaligus.
  void onClearAllPhotos() => _emitPhotos(const []);

  /// Mengatur ulang posisi urutan foto (Drag & Drop Reordering).
  void onReorderPhotos(int oldIndex, int newIndex) {
    final updated = InformationFormPhotos.reorder(
      state.photos,
      oldIndex,
      newIndex,
    );
    if (updated != null) _emitPhotos(updated, clearErrorMessage: false);
  }

  /// Menetapkan dokumen lokal yang dipilih.
  void onSetDocumentMedia(InformationFormMediaItem? media) {
    _emitInput(
      state.copyWith(
        documentMedia: () => media,
        feedFile: media?.name ?? '',
        feedFileError: () => null,
      ),
    );
  }

  /// Menghapus dokumen yang terpasang.
  void onClearDocumentMedia() => onSetDocumentMedia(null);

  /// Mengirim formulir ke backend sesuai mode aktif (Create / Update).
  Future<void> submit({required AuthSessionEntity? session}) async {
    // 1. Guard terhadap concurrent submissions
    if (state.isSubmitting) return;

    // 2. Evaluasi validasi seluruh field
    final titleErr = InformationFormValidators.validateTitle(state.title);
    final textErr = InformationFormValidators.validateText(state.text);
    final fileErr = InformationFormValidators.validateFeedFile(state.feedFile);
    final locErr = InformationFormValidators.validateEventLocation(
      state.eventLocation,
    );
    final photosErr = InformationFormPhotos.validate(
      state.photos,
      maxPhotos: InformationFormState.maxPhotosLimit,
    );
    final coordinateErrs = InformationFormValidators.validateCoordinates(
      state.glat,
      state.glong,
    );
    final glatErr = coordinateErrs.glat;
    final glongErr = coordinateErrs.glong;

    if (titleErr != null ||
        textErr != null ||
        fileErr != null ||
        locErr != null ||
        photosErr != null ||
        glatErr != null ||
        glongErr != null) {
      emit(
        state.copyWith(
          titleError: () => titleErr,
          textError: () => textErr,
          feedFileError: () => fileErr,
          eventLocationError: () => locErr,
          photosError: () => photosErr,
          glatError: () => glatErr,
          glongError: () => glongErr,
          validationAttempt: state.validationAttempt + 1,
        ),
      );
      return;
    }

    _submitCancelToken?.cancel('resubmitted');
    final cancelToken = DioCancellationToken();
    _submitCancelToken = cancelToken;

    emit(
      state.copyWith(
        status: InformationFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    // Pembuatan payload URL/key (Mendukung berkas lokal via mock upload)
    final resolvedPhotos = InformationFormPhotos.payloadUrls(state.photos);

    String? resolvedFile;
    if (state.documentMedia != null) {
      final doc = state.documentMedia!;
      if (doc.isLocal) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        resolvedFile =
            'https://cdn.kawalo.internal/feeds/docs/${timestamp}_${doc.name}';
      } else {
        resolvedFile = doc.remoteUrl ?? doc.displaySource;
      }
    } else {
      resolvedFile = state.feedFile.trimmedOrNull;
    }

    final titleTrimmed = state.title.trim();
    final photosPayload = state.isUpdateMode || resolvedPhotos.isNotEmpty
        ? resolvedPhotos
        : null;
    final textPayload = state.text.trimmedOrNull;
    final locPayload = state.eventLocation.trimmedOrNull;
    final glatPayload = state.glat.trimmedOrNull;
    final glongPayload = state.glong.trimmedOrNull;

    final Either<Failure, InformationItemEntity> result;
    if (state.isCreateMode) {
      result = await createInformationUseCase(
        CreateInformationParams(
          title: titleTrimmed,
          text: textPayload,
          feedFile: resolvedFile,
          photos: photosPayload,
          feedType: state.feedType,
          eventLocation: locPayload,
          glat: glatPayload,
          glong: glongPayload,
          session: session,
          cancelToken: cancelToken,
        ),
      );
    } else {
      final initial = state.initialItem;
      if (initial == null) {
        emit(
          state.copyWith(
            status: InformationFormStatus.failure,
            errorMessage: () => 'Data informasi awal tidak ditemukan.',
          ),
        );
        return;
      }

      result = await updateInformationUseCase(
        UpdateInformationParams(
          id: initial.id,
          title: titleTrimmed,
          text: textPayload,
          feedFile: resolvedFile,
          photos: photosPayload,
          feedType: state.feedType,
          eventLocation: locPayload,
          glat: glatPayload,
          glong: glongPayload,
          includeNulls: true,
          session: session,
          item: initial,
          cancelToken: cancelToken,
        ),
      );
    }

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: InformationFormStatus.failure,
          errorMessage: () => failure.message,
        ),
      ),
      (item) => emit(
        state.copyWith(
          status: InformationFormStatus.success,
          createdOrUpdatedItem: item,
          errorMessage: () => null,
        ),
      ),
    );
  }
}
