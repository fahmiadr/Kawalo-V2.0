import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Pure Value Object payload repositori untuk eksekusi check-out tamu.
///
/// Bertindak sebagai Data Transfer Object di Domain Layer tanpa serialisasi
/// JSON dan independen dari HTTP/Dio.
class CheckoutGuestData extends Equatable {
  /// Membuat instance [CheckoutGuestData].
  const CheckoutGuestData({
    required this.id,
    this.qrUid,
    this.cancelToken,
  });

  /// Identifier numerik unik data tamu (wajib).
  final String id;

  /// Kode QR tamu opsional.
  final String? qrUid;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  @override
  List<Object?> get props => [id, qrUid, cancelToken];
}
