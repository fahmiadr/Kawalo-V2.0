import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';

/// Value object domain yang membungkus kumpulan data informasi beserta
/// transparansi sumber data (apakah berasal dari cache lokal Isar atau server).
///
/// Berfungsi sebagai Query Result / Read Model wrapper tanpa identitas.
class InformationResult extends Equatable {
  /// Membuat instance [InformationResult].
  const InformationResult({required this.items, this.isFromCache = false});

  /// Daftar data catatan informasi / feed.
  final List<InformationItemEntity> items;

  /// Menandakan apakah data bersumber dari cache lokal (offline).
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}
