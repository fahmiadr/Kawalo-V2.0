import 'package:equatable/equatable.dart';

/// Pure DTO model untuk request body batch delete data tamu
/// sesuai kontrak backend `DeleteBatchGuestDto`.
///
/// Digunakan untuk kebutuhan request body HTTP endpoint
/// `DELETE /v1/guests` dengan payload `{ "ids": ["1", "2", ...] }`.
class DeleteBatchGuestRequestModel extends Equatable {
  /// Membuat instance [DeleteBatchGuestRequestModel].
  const DeleteBatchGuestRequestModel({required this.ids});

  /// Daftar identifier numerik unik data tamu yang akan dihapus.
  final List<String> ids;

  /// Mengonversi ke payload JSON untuk request body HTTP.
  Map<String, dynamic> toJson() => {'ids': ids};

  @override
  List<Object?> get props => [ids];
}
