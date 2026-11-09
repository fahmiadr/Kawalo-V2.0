import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Ekstensi lapisan presentasi untuk [GuestItemEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, format tanggal,
/// status linimasa, dan fallback string) tanpa mencemari lapisan Domain.
extension GuestUiExtension on GuestItemEntity {
  /// Identifier tampilan utama (nama tamu jika ada, atau nomor tamu, atau '-').
  String get identifier {
    final name = guestName;
    final number = guestNumber;
    return (name != null && name.isNotEmpty)
        ? name
        : (number != null && number.isNotEmpty ? number : '-');
  }

  /// Nama tamu yang aman untuk tampilan UI.
  String get displayGuestName => guestName.toDisplay();

  /// Mendapatkan nama tamu untuk ditampilkan.
  String get displayName =>
      (guestName != null && guestName!.isNotEmpty) ? guestName! : '-';

  /// Mendapatkan nomor tamu untuk ditampilkan.
  String get displayGuestNumber =>
      (guestNumber != null && guestNumber!.isNotEmpty) ? guestNumber! : '-';

  /// Mendapatkan jenis identitas (KTP/SIM/Paspor).
  String get displayIdentityType =>
      (guestIdentityType != null && guestIdentityType!.isNotEmpty)
      ? guestIdentityType!
      : '-';

  /// Mendapatkan tipe tamu (misal: Visitor, Delivery).
  String get displayGuestType =>
      (guestType != null && guestType!.isNotEmpty) ? guestType! : '-';

  /// Mendapatkan alamat asal tamu.
  String get displayAddress =>
      (guestAddress != null && guestAddress!.isNotEmpty) ? guestAddress! : '-';

  /// Mendapatkan kode akses QR tamu.
  String get displayQrUid =>
      (qrUid != null && qrUid!.isNotEmpty) ? qrUid! : '-';

  /// Mendapatkan email petugas checkout.
  String get displayCheckoutByEmail =>
      (guestCheckoutByEmail != null && guestCheckoutByEmail!.isNotEmpty)
      ? guestCheckoutByEmail!
      : '-';

  /// Mendapatkan nama petugas checkout untuk ditampilkan.
  String get displayCheckoutByName =>
      (guestCheckoutByName != null && guestCheckoutByName!.isNotEmpty)
      ? guestCheckoutByName!
      : '-';

  /// Mendapatkan nama grup untuk ditampilkan.
  String get displayGroupName =>
      (groupName != null && groupName!.isNotEmpty) ? groupName! : '-';

  /// Mendapatkan nomor identitas tamu untuk ditampilkan.
  String get displayIdNumber =>
      (guestIdentity != null && guestIdentity!.isNotEmpty)
      ? guestIdentity!
      : '-';

  /// Teks destinasi yang ramah untuk tampilan UI.
  String get displayDestination =>
      (guestDestination != null && guestDestination!.isNotEmpty)
      ? guestDestination!
      : '-';

  /// Teks kategori tamu yang ramah untuk tampilan UI.
  String get displayCategory =>
      (guestCategory != null && guestCategory!.isNotEmpty)
      ? guestCategory!
      : '-';

  /// Teks keperluan tamu yang ramah untuk tampilan UI.
  String get displayPurpose =>
      (guestPurpose != null && guestPurpose!.isNotEmpty) ? guestPurpose! : '-';

  /// Mendapatkan nama penerima tamu tanpa embel-embel lokasi jika ada.
  String get displayGuestToUserName {
    final name = guestToUserName;
    if (name == null || name.isEmpty) return '-';
    if (name.contains(' - ')) {
      return name.split(' - ').first.trim();
    }
    return name;
  }

  /// Mendapatkan email penerima tamu untuk ditampilkan.
  String get displayGuestToUserEmail =>
      (guestToUserEmail != null && guestToUserEmail!.isNotEmpty)
      ? guestToUserEmail!
      : '-';

  /// Mendapatkan nama petugas pencatat untuk ditampilkan.
  String get displayRecordedBy =>
      (guestCreatorName != null && guestCreatorName!.isNotEmpty)
      ? guestCreatorName!
      : '-';

  /// Mendapatkan email petugas pencatat untuk ditampilkan.
  String get displayRecorderEmail =>
      (guestCreatorEmail != null && guestCreatorEmail!.isNotEmpty)
      ? guestCreatorEmail!
      : '-';

  /// Mendapatkan waktu masuk tamu untuk ditampilkan.
  String get displayEntryTime => (guestDt != null && guestDt!.isNotEmpty)
      ? AppDateFormat.formatRawDate(guestDt)
      : '-';

  /// Mendapatkan waktu konfirmasi kunjungan tamu untuk ditampilkan.
  String get displayConfirmationTime =>
      (guestAckDt != null && guestAckDt!.isNotEmpty)
      ? AppDateFormat.formatRawDate(guestAckDt)
      : '-';

  /// Mendapatkan waktu keluar tamu untuk ditampilkan.
  String get displayExitTime => (guestOutDt != null && guestOutDt!.isNotEmpty)
      ? AppDateFormat.formatRawDate(guestOutDt)
      : '-';

  /// Menentukan apakah kunjungan tamu telah dikonfirmasi.
  bool get isConfirmed =>
      guestAckDt != null && guestAckDt!.isNotEmpty && guestAckDt != '-';

  /// Menentukan apakah tamu telah keluar dari kawasan.
  bool get isExited =>
      guestOutDt != null && guestOutDt!.isNotEmpty && guestOutDt != '-';

  /// Menentukan apakah tamu memiliki data petugas checkout yang sah.
  bool get hasCheckout =>
      (guestCheckoutByEmail != null &&
          guestCheckoutByEmail!.isNotEmpty &&
          guestCheckoutByEmail != '-') ||
      (guestCheckoutByName != null &&
          guestCheckoutByName!.isNotEmpty &&
          guestCheckoutByName != '-');

  /// Label status aktivitas event terakhir pada linimasa.
  String get latestStatusLabel {
    if (isExited) {
      return 'Keluar';
    }
    if (isConfirmed) {
      return 'Konfirmasi';
    }
    return 'Masuk';
  }

  /// Waktu status aktivitas event terakhir pada linimasa.
  String get latestStatusTime {
    if (isExited) {
      return displayExitTime;
    }
    if (isConfirmed) {
      return displayConfirmationTime;
    }
    return displayEntryTime;
  }

  /// Mendapatkan tanggal & waktu pembaruan client untuk ditampilkan.
  String get displayClientUpdatedAt => AppDateFormat.formatRawGreeting(guestDt);
}
