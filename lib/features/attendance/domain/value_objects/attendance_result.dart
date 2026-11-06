import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

/// Ringkasan hasil pemanggilan data absensi beserta transparansi
/// sumber data (apakah data berasal dari cache lokal Isar atau server remote).
class AttendanceResult extends Equatable {
  /// Membuat instance [AttendanceResult].
  const AttendanceResult({
    required this.items,
    this.isFromCache = false,
  });

  /// Daftar data catatan absensi.
  final List<AttendanceItemEntity> items;

  /// Menandakan apakah data bersumber dari cache lokal (offline).
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}
