import 'package:equatable/equatable.dart';

/// Value object domain yang merepresentasikan hasil operasi batch delete
/// informasi / feed.
///
/// Berfungsi sebagai Response Model / Result Value Object murni tanpa
/// identitas (tidak memiliki ID independen).
class DeleteBatchResult extends Equatable {
  /// Membuat instance [DeleteBatchResult].
  const DeleteBatchResult({required this.deletedCount});

  /// Jumlah data informasi yang berhasil dihapus.
  final int deletedCount;

  @override
  List<Object?> get props => [deletedCount];
}
