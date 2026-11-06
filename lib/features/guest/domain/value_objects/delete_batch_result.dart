import 'package:equatable/equatable.dart';

/// Ringkasan hasil operasi penghapusan batch data tamu.
class DeleteBatchResult extends Equatable {
  /// Membuat instance [DeleteBatchResult].
  const DeleteBatchResult({required this.deletedCount});

  /// Jumlah record tamu yang berhasil dihapus dari sistem.
  final int deletedCount;

  @override
  List<Object?> get props => [deletedCount];
}
