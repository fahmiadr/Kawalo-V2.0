import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/utils/app_validator.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
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
       super(_buildInitialState(initialItem));

  /// Use case untuk mempublikasikan feed informasi baru.
  final CreateInformationUseCase createInformationUseCase;

  /// Use case untuk memperbarui feed informasi yang sudah ada.
  final UpdateInformationUseCase updateInformationUseCase;

  final LocationService _locationService;

  AppCancellationToken? _submitCancelToken;
  int _gpsGeneration = 0;

  static InformationFormState _buildInitialState(
    InformationItemEntity? initialItem,
  ) {
    if (initialItem == null) {
      return const InformationFormState(status: InformationFormStatus.ready);
    }

    final initialPhotos = initialItem.photos
        .map(InformationFormMediaItem.fromRemoteUrl)
        .toList();

    InformationFormMediaItem? initialDoc;
    final docFile = initialItem.feedFile;
    if (docFile != null && docFile.trim().isNotEmpty) {
      initialDoc = InformationFormMediaItem.fromRemoteUrl(docFile);
    }

    return InformationFormState(
      mode: InformationFormMode.update,
      status: InformationFormStatus.ready,
      initialItem: initialItem,
      title: initialItem.title ?? '',
      text: initialItem.text ?? '',
      feedType: initialItem.feedType ?? 'GENERAL',
      photos: List<InformationFormMediaItem>.unmodifiable(initialPhotos),
      documentMedia: initialDoc,
      feedFile: initialItem.feedFile ?? '',
      eventLocation: initialItem.eventLocation ?? '',
      glat: initialItem.glat != null ? initialItem.glat.toString() : '',
      glong: initialItem.glong != null ? initialItem.glong.toString() : '',
    );
  }

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

  /// Validasi aturan judul informasi (wajib, max 128 karakter).
  static String? validateTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(
        trimmed,
        fieldName: 'Judul informasi',
      );
    }
    if (value.length > 128) {
      return 'Judul informasi maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan deskripsi informasi (max 1024 karakter).
  static String? validateText(String value) {
    if (value.length > 1024) {
      return 'Deskripsi informasi maksimal 1024 karakter.';
    }
    return null;
  }

  /// Validasi kategori postingan.
  static String? validateFeedType(String value) {
    final upper = value.trim().toUpperCase();
    if (!InformationFeedType.allowedCodes.contains(upper)) {
      return 'Kategori informasi tidak valid.';
    }
    return null;
  }

  /// Validasi batas panjang tautan berkas lampiran.
  static String? validateFeedFile(String value) {
    if (value.length > 2048) {
      return 'Tautan berkas maksimal 2048 karakter.';
    }
    return null;
  }

  /// Validasi nama lokasi kejadian (max 128 karakter).
  static String? validateEventLocation(String value) {
    if (value.length > 128) {
      return 'Nama lokasi maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi angka koordinat garis lintang GPS.
  static String? validateGlat(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 32) {
      return 'Panjang latitude maksimal 32 karakter.';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < -90.0 || parsed > 90.0) {
      return 'Latitude harus berupa angka valid antara -90 dan 90.';
    }
    return null;
  }

  /// Validasi angka koordinat garis bujur GPS.
  static String? validateGlong(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 32) {
      return 'Panjang longitude maksimal 32 karakter.';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < -180.0 || parsed > 180.0) {
      return 'Longitude harus berupa angka valid antara -180 dan 180.';
    }
    return null;
  }

  /// Memperbarui nilai judul postingan.
  void onTitleChanged(String value) {
    emit(
      state.copyWith(
        title: value,
        titleError: () =>
            state.titleError != null ? validateTitle(value) : null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui isi / deskripsi teks postingan.
  void onTextChanged(String value) {
    emit(
      state.copyWith(
        text: value,
        textError: () => state.textError != null ? validateText(value) : null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui kategori tipe postingan
  /// (GENERAL, INCIDENT, JOIN, EVENT, OTHER).
  void onFeedTypeChanged(String value) {
    final upper = value.trim().toUpperCase();
    emit(
      state.copyWith(
        feedType: upper,
        feedTypeError: () => validateFeedType(upper),
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui berkas lampiran feed (URL / text).
  void onFeedFileChanged(String value) {
    emit(
      state.copyWith(
        feedFile: value,
        feedFileError: () => validateFeedFile(value),
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui lokasi kegiatan atau tempat kejadian.
  void onEventLocationChanged(String value) {
    emit(
      state.copyWith(
        eventLocation: value,
        eventLocationError: () => state.eventLocationError != null
            ? validateEventLocation(value)
            : null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui koordinat garis lintang GPS (GLat).
  void onGlatChanged(String value) {
    emit(
      state.copyWith(
        glat: value,
        glatError: () => validateGlat(value),
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui koordinat garis bujur GPS (GLong).
  void onGlongChanged(String value) {
    emit(
      state.copyWith(
        glong: value,
        glongError: () => validateGlong(value),
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memasang titik koordinat lokasi secara terprogram dari GPS
  /// atau pemilih peta.
  void onSetLocationCoordinates({required double lat, required double lng}) {
    emit(
      state.copyWith(
        glat: lat.toString(),
        glong: lng.toString(),
        glatError: () => null,
        glongError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
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
    emit(
      state.copyWith(
        glat: '',
        glong: '',
        glatError: () => null,
        glongError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  static bool _isPhotoMatch(
    InformationFormMediaItem a,
    InformationFormMediaItem b,
  ) {
    return !a.isLoading &&
        !b.isLoading &&
        (a.displaySource == b.displaySource ||
            (a.path != null && a.path == b.path) ||
            (a.remoteUrl != null && a.remoteUrl == b.remoteUrl));
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

    final availableSlots = state.remainingPhotoSlots;
    if (availableSlots <= 0) {
      emit(
        state.copyWith(
          photosError: () =>
              'Maksimal '
              '${InformationFormState.maxPhotosLimit} foto dapat dilampirkan.',
        ),
      );
      return 0;
    }

    final newItemsToAdd = <InformationFormMediaItem>[];
    for (final item in items) {
      if (newItemsToAdd.length >= availableSlots) break;

      final isDuplicate =
          !item.isLoading &&
          (state.photos.any((p) => _isPhotoMatch(p, item)) ||
              newItemsToAdd.any((p) => _isPhotoMatch(p, item)));

      if (!isDuplicate) {
        newItemsToAdd.add(item);
      }
    }

    if (newItemsToAdd.isEmpty) {
      emit(
        state.copyWith(
          photosError: () => items.length == 1
              ? 'Foto tersebut sudah ada dalam lampiran.'
              : 'Foto yang dipilih sudah ada dalam lampiran.',
        ),
      );
      return 0;
    }

    final updated = [...state.photos, ...newItemsToAdd];
    emit(
      state.copyWith(
        photos: updated,
        photosError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
    return newItemsToAdd.length;
  }

  /// Mengganti item foto tertentu berdasarkan [targetId] dengan [newItem].
  bool onReplacePhoto({
    required String targetId,
    required InformationFormMediaItem newItem,
  }) {
    final index = state.photos.indexWhere((p) => p.id == targetId);
    if (index == -1) return false;

    final updated = List<InformationFormMediaItem>.from(state.photos);
    updated[index] = newItem;

    emit(
      state.copyWith(
        photos: updated,
        photosError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
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
    if (index < 0 || index >= state.photos.length) return;
    final updated = List<InformationFormMediaItem>.from(state.photos)
      ..removeAt(index);
    emit(
      state.copyWith(
        photos: updated,
        photosError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menghapus seluruh foto yang dilampirkan sekaligus.
  void onClearAllPhotos() {
    emit(
      state.copyWith(
        photos: const [],
        photosError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Mengatur ulang posisi urutan foto (Drag & Drop Reordering).
  void onReorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.photos.length) return;
    if (newIndex < 0 || newIndex >= state.photos.length) return;
    if (oldIndex == newIndex) return;

    final updated = List<InformationFormMediaItem>.from(state.photos);
    final movedItem = updated.removeAt(oldIndex);
    updated.insert(newIndex, movedItem);

    emit(
      state.copyWith(
        photos: updated,
        photosError: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menetapkan dokumen lokal yang dipilih.
  void onSetDocumentMedia(InformationFormMediaItem? media) {
    emit(
      state.copyWith(
        documentMedia: () => media,
        feedFile: media?.name ?? '',
        feedFileError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menghapus dokumen yang terpasang.
  void onClearDocumentMedia() {
    emit(
      state.copyWith(
        documentMedia: () => null,
        feedFile: '',
        feedFileError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Mengirim formulir ke backend sesuai mode aktif (Create / Update).
  Future<void> submit({required AuthSessionEntity? session}) async {
    // 1. Guard terhadap concurrent submissions
    if (state.isSubmitting) return;

    // 2. Evaluasi validasi seluruh field
    final titleErr = validateTitle(state.title);
    final textErr = validateText(state.text);
    final fileErr = validateFeedFile(state.feedFile);
    final locErr = validateEventLocation(state.eventLocation);
    final hasLoadingPhotos = state.photos.any((p) => p.isLoading);
    final photosErr = state.photos.length > 4
        ? 'Maksimal 4 foto dapat dilampirkan.'
        : hasLoadingPhotos
        ? 'Tunggu hingga semua foto selesai diproses.'
        : null;
    final hasGlat = state.glat.trim().isNotEmpty;
    final hasGlong = state.glong.trim().isNotEmpty;
    var glatErr = validateGlat(state.glat);
    var glongErr = validateGlong(state.glong);
    if (hasGlat != hasGlong) {
      if (!hasGlat) {
        glatErr ??= 'Latitude wajib diisi jika longitude ditentukan.';
      }
      if (!hasGlong) {
        glongErr ??= 'Longitude wajib diisi jika latitude ditentukan.';
      }
    }

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

    final titleTrimmed = state.title.trim();
    final textTrimmed = state.text.trim();
    final fileTrimmed = state.feedFile.trim();
    final locationTrimmed = state.eventLocation.trim();
    final glatTrimmed = state.glat.trim();
    final glongTrimmed = state.glong.trim();

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
    final resolvedPhotos = state.photos.map((item) {
      if (item.isLocal) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return 'https://cdn.kawalo.internal/feeds/photos/'
            '${timestamp}_${item.name}';
      }
      return item.remoteUrl ?? item.displaySource;
    }).toList();

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
    } else if (fileTrimmed.isNotEmpty) {
      resolvedFile = fileTrimmed;
    }

    final photosPayload = state.isUpdateMode
        ? List<String>.from(resolvedPhotos)
        : (resolvedPhotos.isNotEmpty
              ? List<String>.from(resolvedPhotos)
              : null);
    final textPayload = textTrimmed.isNotEmpty ? textTrimmed : null;
    final filePayload = resolvedFile;
    final locPayload = locationTrimmed.isNotEmpty ? locationTrimmed : null;
    final glatPayload = glatTrimmed.isNotEmpty ? glatTrimmed : null;
    final glongPayload = glongTrimmed.isNotEmpty ? glongTrimmed : null;

    if (state.isCreateMode) {
      final params = CreateInformationParams(
        title: titleTrimmed,
        text: textPayload,
        feedFile: filePayload,
        photos: photosPayload,
        feedType: state.feedType,
        eventLocation: locPayload,
        glat: glatPayload,
        glong: glongPayload,
        session: session,
        cancelToken: cancelToken,
      );

      final result = await createInformationUseCase(params);
      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            state.copyWith(
              status: InformationFormStatus.failure,
              errorMessage: () => failure.message,
            ),
          );
        },
        (createdItem) {
          emit(
            state.copyWith(
              status: InformationFormStatus.success,
              createdOrUpdatedItem: createdItem,
              errorMessage: () => null,
            ),
          );
        },
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

      final params = UpdateInformationParams(
        id: initial.id,
        title: titleTrimmed,
        text: textPayload,
        feedFile: filePayload,
        photos: photosPayload,
        feedType: state.feedType,
        eventLocation: locPayload,
        glat: glatPayload,
        glong: glongPayload,
        includeNulls: true,
        session: session,
        item: initial,
        cancelToken: cancelToken,
      );

      final result = await updateInformationUseCase(params);
      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            state.copyWith(
              status: InformationFormStatus.failure,
              errorMessage: () => failure.message,
            ),
          );
        },
        (updatedItem) {
          emit(
            state.copyWith(
              status: InformationFormStatus.success,
              createdOrUpdatedItem: updatedItem,
              errorMessage: () => null,
            ),
          );
        },
      );
    }
  }
}
