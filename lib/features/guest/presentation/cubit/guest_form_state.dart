import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Status siklus proses pengiriman formulir pendaftaran / edit tamu.
enum GuestFormStatus {
  /// Status awal saat formulir pertama kali dimuat.
  initial,

  /// Formulir siap untuk diedit atau diisi pengguna.
  ready,

  /// Sedang memuat master tipe tamu dari API backend.
  loadingMasterTypes,

  /// Formulir sedang dikirim ke server backend.
  submitting,

  /// Formulir berhasil disimpan / diperbarui di backend.
  success,

  /// Terjadi kegagalan saat pengiriman atau pemuatan formulir.
  failure,
}

/// Mode operasi formulir tamu.
enum GuestFormMode {
  /// Mode pendaftaran tamu baru (Create).
  create,

  /// Mode pembaruan data tamu yang sudah terdaftar (Update/Edit).
  update,
}

/// State untuk formulir pendaftaran dan pembaruan data tamu (`GuestFormCubit`).
class GuestFormState extends Equatable {
  /// Membuat instance [GuestFormState].
  const GuestFormState({
    this.mode = GuestFormMode.create,
    this.status = GuestFormStatus.initial,
    this.initialItem,
    this.name = '',
    this.nameError,
    this.destination = '',
    this.destinationError,
    this.guestType = '',
    this.typeError,
    this.identityType,
    this.identityNumber = '',
    this.identityNumberError,
    this.guestNumber = '',
    this.guestNumberError,
    this.purpose = '',
    this.purposeError,
    this.address = '',
    this.addressError,
    this.hostName = '',
    this.hostNameError,
    this.photoUrl,
    this.photoMedia,
    this.photoError,
    this.masterTypes = const <MasterGuestTypeEntity>[],
    this.isLoadingMasterTypes = false,
    this.masterTypesError,
    this.errorMessage,
    this.createdOrUpdatedItem,
    this.validationAttempt = 0,
  });

  /// State awal formulir: kosong untuk create, terisi dari [initialItem]
  /// untuk update.
  factory GuestFormState.initial(GuestItemEntity? initialItem) {
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
      hostName: originalHostName(initialItem),
      photoUrl: initialItem.guestPhoto,
      photoMedia: initialPhotoMedia,
    );
  }

  /// Teks tuan rumah yang tampil di form untuk [item]: nama bebas, atau nama
  /// akun tuan rumah untuk data lama yang hanya punya email.
  static String originalHostName(GuestItemEntity item) =>
      (item.guestToName ?? item.guestToUserName ?? '').trim();

  /// Mode operasi formulir (create / update).
  final GuestFormMode mode;

  /// Status siklus proses formulir.
  final GuestFormStatus status;

  /// Entitas asli jika berada dalam mode pembaruan ([GuestFormMode.update]).
  final GuestItemEntity? initialItem;

  /// Nama lengkap tamu (wajib, max 128 karakter).
  final String name;

  /// Pesan error validasi untuk [name].
  final String? nameError;

  /// Lokasi / rumah / blok destinasi tujuan kunjungan (wajib, max 128).
  final String destination;

  /// Pesan error validasi untuk [destination].
  final String? destinationError;

  /// Tipe tamu dari master tipe tamu aktif (wajib, max 64 karakter).
  final String guestType;

  /// Pesan error validasi untuk [guestType].
  final String? typeError;

  /// Jenis kartu identitas ('KTP', 'SIM', 'PASPOR', 'LAINNYA', atau null
  /// untuk Tanpa Identitas).
  final String? identityType;

  /// Nomor kartu identitas (wajib jika [identityType] dipilih, max 64).
  final String identityNumber;

  /// Pesan error validasi untuk [identityNumber].
  final String? identityNumberError;

  /// Nomor tamu atau nomor plat kendaraan (opsional, max 32 karakter).
  final String guestNumber;

  /// Pesan error validasi untuk [guestNumber].
  final String? guestNumberError;

  /// Keperluan kunjungan tamu (opsional, max 128 karakter).
  final String purpose;

  /// Pesan error validasi untuk [purpose].
  final String? purposeError;

  /// Alamat domisili/asal tamu (opsional, max 512 karakter).
  final String address;

  /// Pesan error validasi untuk [address].
  final String? addressError;

  /// Nama tuan rumah yang diketik bebas (opsional, max 128 karakter).
  final String hostName;

  /// Pesan error validasi untuk [hostName].
  final String? hostNameError;

  /// URL foto tamu yang tersimpan di server backend.
  final String? photoUrl;

  /// Media foto lokal atau remote yang dilampirkan.
  final InformationFormMediaItem? photoMedia;

  /// Pesan error validasi untuk lampiran foto.
  final String? photoError;

  /// Daftar master tipe tamu aktif yang diambil dari backend.
  final List<MasterGuestTypeEntity> masterTypes;

  /// Status pemuatan daftar master tipe tamu.
  final bool isLoadingMasterTypes;

  /// Pesan error saat gagal memuat master tipe tamu.
  final String? masterTypesError;

  /// Pesan kegagalan dari server backend atau use case.
  final String? errorMessage;

  /// Entitas tamu yang berhasil didaftarkan atau diperbarui.
  final GuestItemEntity? createdOrUpdatedItem;

  /// Penghitung percobaan validasi submit untuk memicu auto-focus
  /// ke field pertama yang bermasalah pada lapisan UI.
  final int validationAttempt;

  /// Menandakan apakah sedang dalam mode pendaftaran tamu baru.
  bool get isCreateMode => mode == GuestFormMode.create;

  /// Menandakan apakah sedang dalam mode pembaruan data tamu.
  bool get isUpdateMode => mode == GuestFormMode.update;

  /// Menandakan apakah formulir sedang dalam proses pengiriman ke server.
  bool get isSubmitting => status == GuestFormStatus.submitting;

  /// Menandakan apakah formulir berhasil disimpan ke server.
  bool get isSuccess => status == GuestFormStatus.success;

  /// Menandakan apakah formulir gagal disimpan.
  bool get isFailure => status == GuestFormStatus.failure;

  /// Menandakan apakah jenis identitas dipilih (bukan Tanpa Identitas).
  bool get hasIdentityType =>
      identityType != null && identityType!.trim().isNotEmpty;

  /// Menandakan apakah formulir memiliki perubahan data dibandingkan
  /// nilai awal.
  bool get isDirty {
    if (isCreateMode) {
      return name.trim().isNotEmpty ||
          destination.trim().isNotEmpty ||
          guestType.trim().isNotEmpty ||
          hasIdentityType ||
          identityNumber.trim().isNotEmpty ||
          guestNumber.trim().isNotEmpty ||
          purpose.trim().isNotEmpty ||
          address.trim().isNotEmpty ||
          hostName.trim().isNotEmpty ||
          photoMedia != null ||
          (photoUrl != null && photoUrl!.trim().isNotEmpty);
    }

    final original = initialItem;
    if (original == null) return false;

    final origName = original.guestName ?? '';
    final origDestination = original.guestDestination ?? '';
    final origType = original.guestType ?? '';
    final origIdentityType = original.guestIdentityType;
    final origIdentityNumber = original.guestIdentity ?? '';
    final origGuestNumber = original.guestNumber ?? '';
    final origPurpose = original.guestPurpose ?? '';
    final origAddress = original.guestAddress ?? '';
    final origHostName = originalHostName(original);
    final origPhoto = original.guestPhoto ?? '';

    final currentPhoto = photoMedia?.remoteUrl ?? photoUrl ?? '';

    return name.trim() != origName.trim() ||
        destination.trim() != origDestination.trim() ||
        guestType.trim() != origType.trim() ||
        identityType != origIdentityType ||
        identityNumber.trim() != origIdentityNumber.trim() ||
        guestNumber.trim() != origGuestNumber.trim() ||
        purpose.trim() != origPurpose.trim() ||
        address.trim() != origAddress.trim() ||
        hostName.trim() != origHostName.trim() ||
        currentPhoto.trim() != origPhoto.trim();
  }

  /// Menandakan apakah seluruh isian valid secara logika domain.
  bool get isValid {
    final nameTrimmed = name.trim();
    if (nameTrimmed.isEmpty || nameTrimmed.length > 128) return false;
    if (nameError != null) return false;

    final destTrimmed = destination.trim();
    if (destTrimmed.isEmpty || destTrimmed.length > 128) return false;
    if (destinationError != null) return false;

    final typeTrimmed = guestType.trim();
    if (typeTrimmed.isEmpty || typeTrimmed.length > 64) return false;
    if (typeError != null) return false;

    if (hasIdentityType) {
      final idTrimmed = identityNumber.trim();
      if (idTrimmed.isEmpty || idTrimmed.length > 64) return false;
      if (identityNumberError != null) return false;
    }

    if (guestNumber.length > 32 || guestNumberError != null) return false;
    if (purpose.length > 128 || purposeError != null) return false;
    if (address.length > 512 || addressError != null) return false;
    if (hostName.length > 128 || hostNameError != null) return false;
    if (photoError != null) return false;

    return true;
  }

  /// Menandakan apakah tombol aksi 'Simpan' dapat ditekan pengguna:
  /// - Tidak sedang dalam proses submit (`!isSubmitting`).
  /// - Tidak sedang mengunggah/mengompres foto (`photoMedia?.isLoading != true`).
  /// - Pada mode pembaruan (edit): wajib memiliki perubahan data (`isDirty`).
  bool get canPressSubmit {
    if (isSubmitting) return false;
    if (photoMedia?.isLoading ?? false) return false;
    if (isUpdateMode && !isDirty) return false;
    return true;
  }

  /// Menandakan apakah formulir memenuhi seluruh syarat untuk dikirim:
  /// - Memenuhi syarat penekanan tombol submit (`canPressSubmit`).
  /// - Seluruh input valid sesuai aturan bisnis domain (`isValid`).
  bool get canSubmit => canPressSubmit && isValid;

  /// Mengembalikan nama field pertama yang melanggar validasi agar
  /// lapisan antarmuka UI dapat secara otomatis memfokuskan keyboard ke sana.
  String? get firstInvalidField {
    if (name.trim().isEmpty || name.length > 128 || nameError != null) {
      return 'name';
    }
    if (guestType.trim().isEmpty ||
        guestType.length > 64 ||
        typeError != null) {
      return 'guestType';
    }
    if (hasIdentityType &&
        (identityNumber.trim().isEmpty ||
            identityNumber.length > 64 ||
            identityNumberError != null)) {
      return 'identityNumber';
    }
    if (destination.trim().isEmpty ||
        destination.length > 128 ||
        destinationError != null) {
      return 'destination';
    }
    if (guestNumber.length > 32 || guestNumberError != null) {
      return 'guestNumber';
    }
    if (purpose.length > 128 || purposeError != null) {
      return 'purpose';
    }
    if (address.length > 512 || addressError != null) {
      return 'address';
    }
    if (hostName.length > 128 || hostNameError != null) {
      return 'hostName';
    }
    return null;
  }

  /// Menyalin state dengan nilai-nilai baru secara immutable.
  GuestFormState copyWith({
    GuestFormMode? mode,
    GuestFormStatus? status,
    GuestItemEntity? initialItem,
    String? name,
    String? Function()? nameError,
    String? destination,
    String? Function()? destinationError,
    String? guestType,
    String? Function()? typeError,
    String? Function()? identityType,
    String? identityNumber,
    String? Function()? identityNumberError,
    String? guestNumber,
    String? Function()? guestNumberError,
    String? purpose,
    String? Function()? purposeError,
    String? address,
    String? Function()? addressError,
    String? hostName,
    String? Function()? hostNameError,
    String? Function()? photoUrl,
    InformationFormMediaItem? Function()? photoMedia,
    String? Function()? photoError,
    List<MasterGuestTypeEntity>? masterTypes,
    bool? isLoadingMasterTypes,
    String? Function()? masterTypesError,
    String? Function()? errorMessage,
    GuestItemEntity? createdOrUpdatedItem,
    int? validationAttempt,
  }) {
    return GuestFormState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      initialItem: initialItem ?? this.initialItem,
      name: name ?? this.name,
      nameError: nameError != null ? nameError() : this.nameError,
      destination: destination ?? this.destination,
      destinationError: destinationError != null
          ? destinationError()
          : this.destinationError,
      guestType: guestType ?? this.guestType,
      typeError: typeError != null ? typeError() : this.typeError,
      identityType: identityType != null ? identityType() : this.identityType,
      identityNumber: identityNumber ?? this.identityNumber,
      identityNumberError: identityNumberError != null
          ? identityNumberError()
          : this.identityNumberError,
      guestNumber: guestNumber ?? this.guestNumber,
      guestNumberError: guestNumberError != null
          ? guestNumberError()
          : this.guestNumberError,
      purpose: purpose ?? this.purpose,
      purposeError: purposeError != null ? purposeError() : this.purposeError,
      address: address ?? this.address,
      addressError: addressError != null ? addressError() : this.addressError,
      hostName: hostName ?? this.hostName,
      hostNameError: hostNameError != null
          ? hostNameError()
          : this.hostNameError,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      photoMedia: photoMedia != null ? photoMedia() : this.photoMedia,
      photoError: photoError != null ? photoError() : this.photoError,
      masterTypes: masterTypes ?? this.masterTypes,
      isLoadingMasterTypes: isLoadingMasterTypes ?? this.isLoadingMasterTypes,
      masterTypesError: masterTypesError != null
          ? masterTypesError()
          : this.masterTypesError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      createdOrUpdatedItem: createdOrUpdatedItem ?? this.createdOrUpdatedItem,
      validationAttempt: validationAttempt ?? this.validationAttempt,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    status,
    initialItem,
    name,
    nameError,
    destination,
    destinationError,
    guestType,
    typeError,
    identityType,
    identityNumber,
    identityNumberError,
    guestNumber,
    guestNumberError,
    purpose,
    purposeError,
    address,
    addressError,
    hostName,
    hostNameError,
    photoUrl,
    photoMedia,
    photoError,
    masterTypes,
    isLoadingMasterTypes,
    masterTypesError,
    errorMessage,
    createdOrUpdatedItem,
    validationAttempt,
  ];
}
