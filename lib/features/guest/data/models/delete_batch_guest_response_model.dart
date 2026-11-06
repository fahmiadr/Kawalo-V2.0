import 'package:equatable/equatable.dart';

/// Pure DTO model untuk response batch delete data tamu
/// sesuai kontrak backend `DeleteBatchGuestResponseDto`.
///
/// Merupakan Pure DTO tanpa logika bisnis, tanpa fallback, dan tanpa sanitasi.
/// Seluruh proses sanitasi dan pemetaan nilai default didelegasikan ke
/// mapper pada Anti-Corruption Layer.
class DeleteBatchGuestResponseModel extends Equatable {
  /// Membuat instance [DeleteBatchGuestResponseModel].
  const DeleteBatchGuestResponseModel({required this.deletedCount});

  /// Mengonversi JSON Map dari backend menjadi objek
  /// [DeleteBatchGuestResponseModel] secara murni tanpa sanitasi.
  factory DeleteBatchGuestResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeleteBatchGuestResponseModel(
      deletedCount: json['deleted_count'] as int,
    );
  }

  /// Jumlah data tamu yang dihapus sesuai response server.
  final int deletedCount;

  @override
  List<Object?> get props => [deletedCount];
}
