import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/utils/trimmed_or_null.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_validators.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/form_media_uploader.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Cubit pengelola alur logika bisnis dan validasi formulir pendaftaran
/// serta pembaruan data tamu (Create & Update).
class GuestFormCubit extends Cubit<GuestFormState> {
  /// Membuat instance [GuestFormCubit].
  GuestFormCubit({
    required this.createGuestUseCase,
    required this.updateGuestUseCase,
    required this.guestRepository,
    required UploadRepository uploadRepository,
    GuestItemEntity? initialItem,
  }) : _uploadRepository = uploadRepository,
       super(GuestFormState.initial(initialItem)) {
    loadMasterData();
  }

  /// Use case untuk mendaftarkan tamu baru.
  final CreateGuestUseCase createGuestUseCase;

  /// Use case untuk memperbarui data tamu yang sudah ada.
  final UpdateGuestUseCase updateGuestUseCase;

  /// Repositori data tamu untuk memuat master tipe tamu.
  final GuestRepository guestRepository;

  final UploadRepository _uploadRepository;

  AppCancellationToken? _masterCancelToken;
  AppCancellationToken? _submitCancelToken;

  @override
  Future<void> close() {
    _masterCancelToken?.cancel('cubit_closed');
    _submitCancelToken?.cancel('cubit_closed');
    return super.close();
  }

  GuestFormStatus _statusOnInput() {
    return state.status == GuestFormStatus.failure
        ? GuestFormStatus.ready
        : state.status;
  }

  void _emitInput(GuestFormState next) {
    emit(next.copyWith(errorMessage: () => null, status: _statusOnInput()));
  }

  /// [next] unless a submit is in flight, which master loading must not
  /// interrupt.
  GuestFormStatus _statusUnlessSubmitting(GuestFormStatus next) {
    return state.status == GuestFormStatus.submitting ? state.status : next;
  }

  AppCancellationToken _beginMasterLoad() {
    _masterCancelToken?.cancel('reloading');
    return _masterCancelToken = DioCancellationToken();
  }

  /// Memuat master tipe tamu dari API backend.
  Future<void> loadMasterData() async {
    final cancelToken = _beginMasterLoad();

    emit(
      state.copyWith(
        status: _statusUnlessSubmitting(GuestFormStatus.loadingMasterTypes),
        isLoadingMasterTypes: true,
        masterTypesError: () => null,
        errorMessage: () => null,
      ),
    );

    final typesResult = await guestRepository.getMasterGuestTypes(
      cancelToken: cancelToken,
    );

    if (isClosed) return;

    var types = state.masterTypes;
    String? typesError;
    typesResult.fold(
      (failure) => typesError = failure.message,
      (data) => types = data,
    );

    emit(
      state.copyWith(
        status: _statusUnlessSubmitting(GuestFormStatus.ready),
        isLoadingMasterTypes: false,
        masterTypes: types,
        masterTypesError: () => typesError,
        errorMessage: () => typesError,
      ),
    );
  }

  /// Memuat ulang daftar master tipe tamu dari API backend.
  Future<void> loadMasterGuestTypes() async {
    final cancelToken = _beginMasterLoad();

    emit(
      state.copyWith(
        status: _statusUnlessSubmitting(GuestFormStatus.loadingMasterTypes),
        isLoadingMasterTypes: true,
        masterTypesError: () => null,
      ),
    );

    final result = await guestRepository.getMasterGuestTypes(
      cancelToken: cancelToken,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: _statusUnlessSubmitting(GuestFormStatus.ready),
          isLoadingMasterTypes: false,
          masterTypesError: () => failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: _statusUnlessSubmitting(GuestFormStatus.ready),
          isLoadingMasterTypes: false,
          masterTypes: data,
          masterTypesError: () => null,
        ),
      ),
    );
  }

  /// Memperbarui nilai nama tamu dan memvalidasi.
  void onNameChanged(String value) {
    final error = GuestFormValidators.validateName(value);
    _emitInput(state.copyWith(name: value, nameError: () => error));
  }

  /// Memperbarui destinasi tujuan dan memvalidasi.
  void onDestinationChanged(String value) {
    final error = GuestFormValidators.validateDestination(value);
    _emitInput(
      state.copyWith(destination: value, destinationError: () => error),
    );
  }

  /// Memperbarui tipe tamu yang dipilih.
  void onGuestTypeChanged(String value) {
    final error = GuestFormValidators.validateGuestType(value);
    _emitInput(state.copyWith(guestType: value, typeError: () => error));
  }

  /// Memperbarui jenis kartu identitas (KTP, SIM, Paspor, atau null).
  void onIdentityTypeChanged(String? value) {
    final normalized = value.trimmedOrNull;

    if (normalized == null) {
      _emitInput(
        state.copyWith(
          identityType: () => null,
          identityNumber: '',
          identityNumberError: () => null,
        ),
      );
      return;
    }

    final error = GuestFormValidators.validateIdentityNumber(
      state.identityNumber,
      isIdentityRequired: true,
    );

    _emitInput(
      state.copyWith(
        identityType: () => normalized,
        identityNumberError: () => error,
      ),
    );
  }

  /// Memperbarui nomor identitas tamu.
  void onIdentityNumberChanged(String value) {
    final error = GuestFormValidators.validateIdentityNumber(
      value,
      isIdentityRequired: state.hasIdentityType,
    );

    _emitInput(
      state.copyWith(identityNumber: value, identityNumberError: () => error),
    );
  }

  /// Memperbarui nomor tamu / plat kendaraan.
  void onGuestNumberChanged(String value) {
    final error = GuestFormValidators.validateGuestNumber(value);
    _emitInput(
      state.copyWith(guestNumber: value, guestNumberError: () => error),
    );
  }

  /// Memperbarui keperluan kunjungan.
  void onPurposeChanged(String value) {
    final error = GuestFormValidators.validatePurpose(value);
    _emitInput(state.copyWith(purpose: value, purposeError: () => error));
  }

  /// Memperbarui alamat domisili/asal tamu.
  void onAddressChanged(String value) {
    final error = GuestFormValidators.validateAddress(value);
    _emitInput(state.copyWith(address: value, addressError: () => error));
  }

  /// Memperbarui nama tuan rumah yang diketik bebas.
  void onHostNameChanged(String value) {
    final error = GuestFormValidators.validateHostName(value);
    _emitInput(state.copyWith(hostName: value, hostNameError: () => error));
  }

  /// Memperbarui lampiran media foto tamu.
  void onPhotoMediaChanged(InformationFormMediaItem? media) {
    _emitInput(
      state.copyWith(
        photoMedia: () => media,
        photoUrl: () => media?.remoteUrl,
        photoError: () => null,
      ),
    );
  }

  /// Menghapus lampiran foto tamu.
  void onRemovePhoto() => onPhotoMediaChanged(null);

  void _patchPhoto(
    String id,
    InformationFormMediaItem Function(InformationFormMediaItem) update,
  ) {
    final media = state.photoMedia;
    if (isClosed || media == null || media.id != id) return;
    emit(state.copyWith(photoMedia: () => update(media)));
  }

  /// Hosts the local photo (if any) and returns how many uploads failed.
  Future<int> _uploadPendingPhoto() {
    final media = state.photoMedia;
    return FormMediaUploader.uploadPending(
      [?media],
      patch: _patchPhoto,
      isCancelled: () => isClosed,
      upload: (item, onProgress) => _uploadRepository.uploadImage(
        item.toAppMediaFile(),
        onProgress: onProgress,
      ),
    );
  }

  /// Mengirim formulir pendaftaran atau pembaruan tamu ke server backend.
  Future<void> submit({AuthSessionEntity? session}) async {
    if (state.isSubmitting) return;

    final nameTrimmed = state.name.trim();
    final destTrimmed = state.destination.trim();
    final typeTrimmed = state.guestType.trim();
    final idNumberTrimmed = state.identityNumber.trim();
    final isIdentityRequired = state.hasIdentityType;

    final nameErr = GuestFormValidators.validateName(nameTrimmed);
    final destErr = GuestFormValidators.validateDestination(destTrimmed);
    final typeErr = GuestFormValidators.validateGuestType(typeTrimmed);
    final idErr = GuestFormValidators.validateIdentityNumber(
      idNumberTrimmed,
      isIdentityRequired: isIdentityRequired,
    );
    final numErr = GuestFormValidators.validateGuestNumber(state.guestNumber);
    final purposeErr = GuestFormValidators.validatePurpose(state.purpose);
    final addressErr = GuestFormValidators.validateAddress(state.address);
    final hostErr = GuestFormValidators.validateHostName(state.hostName);

    final hasErrors =
        nameErr != null ||
        destErr != null ||
        typeErr != null ||
        idErr != null ||
        numErr != null ||
        purposeErr != null ||
        addressErr != null ||
        hostErr != null;

    if (hasErrors) {
      emit(
        state.copyWith(
          nameError: () => nameErr,
          destinationError: () => destErr,
          typeError: () => typeErr,
          identityNumberError: () => idErr,
          guestNumberError: () => numErr,
          purposeError: () => purposeErr,
          addressError: () => addressErr,
          hostNameError: () => hostErr,
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
        status: GuestFormStatus.submitting,
        errorMessage: () => null,
        validationAttempt: state.validationAttempt + 1,
      ),
    );

    // The local photo is hosted first so the payload only carries a real URL.
    final failedUploads = await _uploadPendingPhoto();
    if (isClosed) return;
    if (failedUploads > 0) {
      emit(
        state.copyWith(
          status: GuestFormStatus.failure,
          errorMessage: () => FormMediaUploader.failureMessage(failedUploads),
        ),
      );
      return;
    }

    final resolvedPhotoUrl =
        state.photoMedia?.remoteUrl ?? state.photoUrl.trimmedOrNull;
    final identityNumberPayload = isIdentityRequired
        ? idNumberTrimmed.trimmedOrNull
        : null;
    final identityTypePayload = isIdentityRequired ? state.identityType : null;
    final guestNumberPayload = state.guestNumber.trimmedOrNull;
    final purposePayload = state.purpose.trimmedOrNull;
    final addressPayload = state.address.trimmedOrNull;
    final hostNamePayload = state.hostName.trimmedOrNull;

    final Either<Failure, GuestItemEntity> result;
    if (state.isCreateMode) {
      result = await createGuestUseCase(
        CreateGuestParams(
          guestName: nameTrimmed,
          guestDestination: destTrimmed,
          guestType: typeTrimmed,
          guestIdentity: identityNumberPayload,
          guestIdentityType: identityTypePayload,
          guestNumber: guestNumberPayload,
          guestPurpose: purposePayload,
          guestAddress: addressPayload,
          guestToName: hostNamePayload,
          guestPhoto: resolvedPhotoUrl,
          session: session,
          cancelToken: cancelToken,
        ),
      );
    } else {
      final initial = state.initialItem!;
      // A retyped host no longer matches the linked member account, so the
      // email is cleared; an untouched host keeps both fields as stored.
      final hostChanged =
          state.hostName.trim() != GuestFormState.originalHostName(initial);
      result = await updateGuestUseCase(
        UpdateGuestParams(
          id: initial.id,
          item: initial,
          guestName: nameTrimmed,
          guestDestination: destTrimmed,
          guestType: typeTrimmed,
          guestIdentity: identityNumberPayload,
          guestIdentityType: identityTypePayload,
          guestNumber: guestNumberPayload,
          guestPurpose: purposePayload,
          guestAddress: addressPayload,
          guestToUserEmail: hostChanged ? null : initial.guestToUserEmail,
          guestToName: hostChanged ? hostNamePayload : initial.guestToName,
          guestPhoto: resolvedPhotoUrl,
          includeNulls: true,
          session: session,
          cancelToken: cancelToken,
        ),
      );
    }

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GuestFormStatus.failure,
          errorMessage: () => failure.message,
        ),
      ),
      (guest) => emit(
        state.copyWith(
          status: GuestFormStatus.success,
          createdOrUpdatedItem: guest,
          errorMessage: () => null,
        ),
      ),
    );
  }
}
