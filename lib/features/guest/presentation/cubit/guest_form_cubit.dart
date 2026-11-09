import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/utils/app_validator.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_params.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Cubit pengelola alur logika bisnis dan validasi formulir pendaftaran
/// serta pembaruan data tamu (Create & Update).
class GuestFormCubit extends Cubit<GuestFormState> {
  /// Membuat instance [GuestFormCubit].
  GuestFormCubit({
    required this.createGuestUseCase,
    required this.updateGuestUseCase,
    required this.getMasterGuestTypesUseCase,
    required this.getGroupMembersUseCase,
    GuestItemEntity? initialItem,
  }) : super(_buildInitialState(initialItem)) {
    loadMasterData();
  }

  /// Use case untuk mendaftarkan tamu baru.
  final CreateGuestUseCase createGuestUseCase;

  /// Use case untuk memperbarui data tamu yang sudah ada.
  final UpdateGuestUseCase updateGuestUseCase;

  /// Use case untuk memuat master tipe tamu.
  final GetMasterGuestTypesUseCase getMasterGuestTypesUseCase;

  /// Use case untuk memuat daftar anggota grup (host warga).
  final GetGroupMembersUseCase getGroupMembersUseCase;

  AppCancellationToken? _masterCancelToken;
  AppCancellationToken? _submitCancelToken;

  static GuestFormState _buildInitialState(GuestItemEntity? initialItem) {
    if (initialItem == null) {
      return const GuestFormState(status: GuestFormStatus.ready);
    }

    InformationFormMediaItem? initialPhotoMedia;
    final photo = initialItem.guestPhoto;
    if (photo != null && photo.trim().isNotEmpty) {
      initialPhotoMedia = InformationFormMediaItem.fromRemoteUrl(photo.trim());
    }

    return GuestFormState(
      mode: GuestFormMode.update,
      status: GuestFormStatus.ready,
      initialItem: initialItem,
      name: initialItem.guestName ?? '',
      destination: initialItem.guestDestination ?? '',
      guestType: initialItem.guestType ?? '',
      identityType: initialItem.guestIdentityType,
      identityNumber: initialItem.guestIdentity ?? '',
      guestNumber: initialItem.guestNumber ?? '',
      purpose: initialItem.guestPurpose ?? '',
      address: initialItem.guestAddress ?? '',
      hostEmail: initialItem.guestToUserEmail,
      photoUrl: initialItem.guestPhoto,
      photoMedia: initialPhotoMedia,
      category: initialItem.guestCategory ?? '',
    );
  }

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

  /// Validasi aturan nama tamu (wajib, max 128 karakter).
  static String? validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(trimmed, fieldName: 'Nama tamu');
    }
    if (value.length > 128) {
      return 'Nama tamu maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan destinasi kunjungan (wajib, max 128 karakter).
  static String? validateDestination(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(
        trimmed,
        fieldName: 'Destinasi kunjungan',
      );
    }
    if (value.length > 128) {
      return 'Destinasi kunjungan maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan tipe tamu (wajib, max 64 karakter).
  static String? validateGuestType(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(
        trimmed,
        customMessage: 'Tipe tamu wajib dipilih.',
      );
    }
    if (value.length > 64) {
      return 'Tipe tamu maksimal 64 karakter.';
    }
    return null;
  }

  /// Validasi aturan nomor identitas (wajib jika jenis identitas dipilih,
  /// max 64 karakter).
  static String? validateIdentityNumber(
    String value, {
    required bool isIdentityRequired,
  }) {
    if (!isIdentityRequired) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(
        trimmed,
        customMessage:
            'Nomor identitas wajib diisi jika jenis identitas dipilih.',
      );
    }
    if (value.length > 64) {
      return 'Nomor identitas maksimal 64 karakter.';
    }
    return null;
  }

  /// Validasi aturan nomor tamu / plat kendaraan (opsional, max 32 karakter).
  static String? validateGuestNumber(String value) {
    if (value.length > 32) {
      return 'Nomor tamu maksimal 32 karakter.';
    }
    return null;
  }

  /// Validasi aturan keperluan kunjungan (opsional, max 128 karakter).
  static String? validatePurpose(String value) {
    if (value.length > 128) {
      return 'Keperluan kunjungan maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan alamat asal (opsional, max 512 karakter).
  static String? validateAddress(String value) {
    if (value.length > 512) {
      return 'Alamat asal maksimal 512 karakter.';
    }
    return null;
  }

  /// Memuat master data (tipe tamu & warga) dari API backend secara simultan.
  Future<void> loadMasterData() async {
    _masterCancelToken?.cancel('reloading');
    final cancelToken = DioCancellationToken();
    _masterCancelToken = cancelToken;

    emit(
      state.copyWith(
        status: state.status == GuestFormStatus.submitting
            ? state.status
            : GuestFormStatus.loadingMasterTypes,
        isLoadingMasterTypes: true,
        isLoadingMasterHosts: true,
        masterTypesError: () => null,
        masterHostsError: () => null,
        errorMessage: () => null,
      ),
    );

    final results = await Future.wait([
      getMasterGuestTypesUseCase(
        GetMasterGuestTypesParams(cancelToken: cancelToken),
      ),
      getGroupMembersUseCase(GetGroupMembersParams(cancelToken: cancelToken)),
    ]);

    if (isClosed) return;

    final typesResult =
        results[0] as Either<Failure, List<MasterGuestTypeEntity>>;
    final hostsResult = results[1] as Either<Failure, List<GroupMemberEntity>>;

    var types = state.masterTypes;
    var hosts = state.masterHosts;
    String? typesError;
    String? hostsError;

    typesResult.fold(
      (failure) => typesError = failure.message,
      (data) => types = data,
    );

    hostsResult.fold(
      (failure) => hostsError = failure.message,
      (data) => hosts = data,
    );

    emit(
      state.copyWith(
        status: state.status == GuestFormStatus.submitting
            ? state.status
            : GuestFormStatus.ready,
        isLoadingMasterTypes: false,
        isLoadingMasterHosts: false,
        masterTypes: types,
        masterHosts: hosts,
        masterTypesError: () => typesError,
        masterHostsError: () => hostsError,
        errorMessage: () => typesError ?? hostsError,
      ),
    );
  }

  /// Memuat ulang daftar master tipe tamu dari API backend.
  Future<void> loadMasterGuestTypes() async {
    _masterCancelToken?.cancel('reloading');
    final cancelToken = DioCancellationToken();
    _masterCancelToken = cancelToken;

    emit(
      state.copyWith(
        status: state.status == GuestFormStatus.submitting
            ? state.status
            : GuestFormStatus.loadingMasterTypes,
        isLoadingMasterTypes: true,
        masterTypesError: () => null,
      ),
    );

    final result = await getMasterGuestTypesUseCase(
      GetMasterGuestTypesParams(cancelToken: cancelToken),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: state.status == GuestFormStatus.submitting
                ? state.status
                : GuestFormStatus.ready,
            isLoadingMasterTypes: false,
            masterTypesError: () => failure.message,
          ),
        );
      },
      (data) {
        emit(
          state.copyWith(
            status: state.status == GuestFormStatus.submitting
                ? state.status
                : GuestFormStatus.ready,
            isLoadingMasterTypes: false,
            masterTypes: data,
            masterTypesError: () => null,
          ),
        );
      },
    );
  }

  /// Memuat ulang daftar warga/host dari API backend.
  Future<void> loadMasterHosts() async {
    _masterCancelToken?.cancel('reloading');
    final cancelToken = DioCancellationToken();
    _masterCancelToken = cancelToken;

    emit(
      state.copyWith(isLoadingMasterHosts: true, masterHostsError: () => null),
    );

    final result = await getGroupMembersUseCase(
      GetGroupMembersParams(cancelToken: cancelToken),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoadingMasterHosts: false,
            masterHostsError: () => failure.message,
          ),
        );
      },
      (data) {
        emit(
          state.copyWith(
            isLoadingMasterHosts: false,
            masterHosts: data,
            masterHostsError: () => null,
          ),
        );
      },
    );
  }

  /// Memperbarui nilai nama tamu dan memvalidasi.
  void onNameChanged(String value) {
    final error = validateName(value);
    emit(
      state.copyWith(
        name: value,
        nameError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui destinasi tujuan dan memvalidasi.
  void onDestinationChanged(String value) {
    final error = validateDestination(value);
    emit(
      state.copyWith(
        destination: value,
        destinationError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui tipe tamu yang dipilih.
  void onGuestTypeChanged(String value) {
    final error = validateGuestType(value);
    emit(
      state.copyWith(
        guestType: value,
        typeError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui jenis kartu identitas (KTP, SIM, Paspor, atau null).
  void onIdentityTypeChanged(String? value) {
    final trimmed = value?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final isIdentityRequired = normalized != null;

    if (!isIdentityRequired) {
      emit(
        state.copyWith(
          identityType: () => null,
          identityNumber: '',
          identityNumberError: () => null,
          errorMessage: () => null,
          status: _statusOnInput(),
        ),
      );
      return;
    }

    final error = validateIdentityNumber(
      state.identityNumber,
      isIdentityRequired: true,
    );

    emit(
      state.copyWith(
        identityType: () => normalized,
        identityNumberError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui nomor identitas tamu.
  void onIdentityNumberChanged(String value) {
    final isIdentityRequired = state.hasIdentityType;
    final error = validateIdentityNumber(
      value,
      isIdentityRequired: isIdentityRequired,
    );

    emit(
      state.copyWith(
        identityNumber: value,
        identityNumberError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui nomor tamu / plat kendaraan.
  void onGuestNumberChanged(String value) {
    final error = validateGuestNumber(value);
    emit(
      state.copyWith(
        guestNumber: value,
        guestNumberError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui keperluan kunjungan.
  void onPurposeChanged(String value) {
    final error = validatePurpose(value);
    emit(
      state.copyWith(
        purpose: value,
        purposeError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui alamat domisili/asal tamu.
  void onAddressChanged(String value) {
    final error = validateAddress(value);
    emit(
      state.copyWith(
        address: value,
        addressError: () => error,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui email warga yang dikunjungi.
  void onHostEmailChanged(String? value) {
    final trimmed = value?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    emit(
      state.copyWith(
        hostEmail: () => normalized,
        hostEmailError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui lampiran media foto tamu.
  void onPhotoMediaChanged(InformationFormMediaItem? media) {
    emit(
      state.copyWith(
        photoMedia: () => media,
        photoUrl: () => media?.remoteUrl,
        photoError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Menghapus lampiran foto tamu.
  void onRemovePhoto() {
    emit(
      state.copyWith(
        photoMedia: () => null,
        photoUrl: () => null,
        photoError: () => null,
        errorMessage: () => null,
        status: _statusOnInput(),
      ),
    );
  }

  /// Memperbarui kategori kunjungan tamu.
  void onCategoryChanged(String value) {
    emit(
      state.copyWith(
        category: value,
        errorMessage: () => null,
        status: _statusOnInput(),
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

    final nameErr = validateName(nameTrimmed);
    final destErr = validateDestination(destTrimmed);
    final typeErr = validateGuestType(typeTrimmed);
    final idErr = validateIdentityNumber(
      idNumberTrimmed,
      isIdentityRequired: isIdentityRequired,
    );
    final numErr = validateGuestNumber(state.guestNumber);
    final purposeErr = validatePurpose(state.purpose);
    final addressErr = validateAddress(state.address);

    final hasErrors =
        nameErr != null ||
        destErr != null ||
        typeErr != null ||
        idErr != null ||
        numErr != null ||
        purposeErr != null ||
        addressErr != null;

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

    // Resolusi URL foto (mendukung berkas remote maupun berkas lokal)
    String? resolvedPhotoUrl;
    if (state.photoMedia != null) {
      if (state.photoMedia!.remoteUrl != null &&
          state.photoMedia!.remoteUrl!.isNotEmpty) {
        resolvedPhotoUrl = state.photoMedia!.remoteUrl;
      } else {
        resolvedPhotoUrl =
            'https://cdn.kawalo.internal/guests/photos/${state.photoMedia!.name}';
      }
    } else if (state.photoUrl != null && state.photoUrl!.trim().isNotEmpty) {
      resolvedPhotoUrl = state.photoUrl!.trim();
    }

    final identityNumberPayload =
        isIdentityRequired && idNumberTrimmed.isNotEmpty
        ? idNumberTrimmed
        : null;

    final guestNumberPayload = state.guestNumber.trim().isNotEmpty
        ? state.guestNumber.trim()
        : null;

    final purposePayload = state.purpose.trim().isNotEmpty
        ? state.purpose.trim()
        : null;

    final addressPayload = state.address.trim().isNotEmpty
        ? state.address.trim()
        : null;

    final hostEmailPayload = state.hostEmail?.trim().isNotEmpty == true
        ? state.hostEmail!.trim()
        : null;

    if (state.isCreateMode) {
      final params = CreateGuestParams(
        guestName: nameTrimmed,
        guestDestination: destTrimmed,
        guestType: typeTrimmed,
        guestIdentity: identityNumberPayload,
        guestIdentityType: isIdentityRequired ? state.identityType : null,
        guestNumber: guestNumberPayload,
        guestPurpose: purposePayload,
        guestAddress: addressPayload,
        guestToUserEmail: hostEmailPayload,
        guestPhoto: resolvedPhotoUrl,
        session: session,
        cancelToken: cancelToken,
      );

      final result = await createGuestUseCase(params);

      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            state.copyWith(
              status: GuestFormStatus.failure,
              errorMessage: () => failure.message,
            ),
          );
        },
        (guest) {
          emit(
            state.copyWith(
              status: GuestFormStatus.success,
              createdOrUpdatedItem: guest,
              errorMessage: () => null,
            ),
          );
        },
      );
    } else {
      final initial = state.initialItem!;
      final params = UpdateGuestParams(
        id: initial.id,
        item: initial,
        guestName: nameTrimmed,
        guestDestination: destTrimmed,
        guestType: typeTrimmed,
        guestIdentity: identityNumberPayload,
        guestIdentityType: isIdentityRequired ? state.identityType : null,
        guestNumber: guestNumberPayload,
        guestPurpose: purposePayload,
        guestAddress: addressPayload,
        guestToUserEmail: hostEmailPayload,
        guestPhoto: resolvedPhotoUrl,
        includeNulls: true,
        session: session,
        cancelToken: cancelToken,
      );

      final result = await updateGuestUseCase(params);

      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            state.copyWith(
              status: GuestFormStatus.failure,
              errorMessage: () => failure.message,
            ),
          );
        },
        (guest) {
          emit(
            state.copyWith(
              status: GuestFormStatus.success,
              createdOrUpdatedItem: guest,
              errorMessage: () => null,
            ),
          );
        },
      );
    }
  }
}
