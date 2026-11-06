import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

/// Hasil query data tamu pada lapisan domain yang menyertakan
/// informasi transparansi sumber data (cache offline vs server remote).
class GuestResult extends Equatable {
  /// Membuat instance [GuestResult].
  const GuestResult({
    required this.items,
    this.isFromCache = false,
  });

  /// Daftar item data tamu.
  final List<GuestItemEntity> items;

  /// Penanda apakah data berasal dari cache lokal (offline fallback).
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}
