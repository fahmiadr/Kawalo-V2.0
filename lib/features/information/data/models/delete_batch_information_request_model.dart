import 'package:equatable/equatable.dart';

/// Pure DTO model untuk request body batch delete informasi
/// sesuai kontrak backend `DeleteBatchInformationDto`.
///
/// Digunakan untuk kebutuhan request body HTTP endpoint
/// `DELETE /v1/information` dengan payload `{ "ids": ["1", "2", ...] }`.
class DeleteBatchInformationRequestModel extends Equatable {
  /// Membuat instance [DeleteBatchInformationRequestModel].
  const DeleteBatchInformationRequestModel({required this.ids});

  /// Daftar identifier numerik unik feed informasi yang akan dihapus.
  final List<String> ids;

  /// Mengonversi ke payload JSON untuk request body HTTP.
  Map<String, dynamic> toJson() => {'ids': ids};

  @override
  List<Object?> get props => [ids];
}
