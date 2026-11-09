import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload HTTP request check-out tamu
/// sesuai kontrak backend `CheckoutGuestDto`.
class CheckoutGuestModel extends Equatable {
  /// Membuat instance [CheckoutGuestModel].
  const CheckoutGuestModel({this.qrUid});

  /// Kode akses QR khusus tamu (opsional).
  final String? qrUid;

  /// Mengonversi payload menjadi representasi Map JSON.
  Map<String, dynamic> toJson() {
    return {if (qrUid != null) 'qr_uid': qrUid};
  }

  @override
  List<Object?> get props => [qrUid];
}
