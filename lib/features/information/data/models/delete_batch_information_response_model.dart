import 'package:equatable/equatable.dart';

/// Pure DTO model untuk response batch delete informasi
/// sesuai kontrak backend `DeleteBatchInformationResponseDto`.
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi.
/// Seluruh proses sanitasi dan pemetaan nilai default didelegasikan ke
/// mapper pada Anti-Corruption Layer.
class DeleteBatchInformationResponseModel extends Equatable {
  /// Membuat instance [DeleteBatchInformationResponseModel].
  const DeleteBatchInformationResponseModel({required this.deletedCount});

  /// Mengonversi JSON Map dari backend menjadi objek
  /// [DeleteBatchInformationResponseModel] secara murni tanpa sanitasi.
  factory DeleteBatchInformationResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeleteBatchInformationResponseModel(
      deletedCount: json['deleted_count'] as int,
    );
  }

  /// Jumlah data informasi yang dihapus sesuai response server.
  final int deletedCount;

  @override
  List<Object?> get props => [deletedCount];
}
