import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';

/// Value object domain pembungkus hasil query data personil operasional
/// dengan transparansi sumber data (cache offline vs server remote).
class OperationalResult extends Equatable {
  /// Membuat instance [OperationalResult].
  const OperationalResult({
    required this.items,
    this.isFromCache = false,
  });

  /// Daftar item data personil operasional.
  final List<OperationalItemEntity> items;

  /// Penanda apakah data berasal dari cache lokal (offline fallback).
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}
