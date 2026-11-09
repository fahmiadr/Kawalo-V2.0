/// @docImport 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_bottom_overlay.dart';
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ============================================================================
// VALUE OBJECT / STATE (GoF): Uni-Directional Flow Overlay State
// ============================================================================

const _sentinel = Object();

/// State antarmuka untuk [MapPickerBottomOverlay] yang sepenuhnya
/// merefleksikan alur data satu arah (Uni-Directional Data Flow / UDF).
@immutable
class MapPickerOverlayState extends Equatable {
  const MapPickerOverlayState({
    this.isLocatingUser = false,
    this.isResolvingAddress = false,
    this.hasGeocodeError = false,
    this.hasConfirmedFix = false,
    this.hasUserInteracted = false,
    this.resolvedAddress,
  });

  /// Status pencarian posisi GPS pengguna.
  final bool isLocatingUser;

  /// Status proses reverse geocoding alamat jalan.
  final bool isResolvingAddress;

  /// Apakah resolusi alamat jalan mengalami kegagalan.
  final bool hasGeocodeError;

  /// Apakah titik lokasi telah memiliki fix koordinat GPS terkonfirmasi.
  final bool hasConfirmedFix;

  /// Apakah pengguna telah melakukan interaksi geser/zoom secara manual.
  final bool hasUserInteracted;

  /// Alamat jalan yang berhasil diperoleh dari reverse geocoding.
  final String? resolvedAddress;

  /// Apakah tombol konfirmasi titik dapat diaktifkan.
  bool get canConfirm =>
      !isLocatingUser && (hasConfirmedFix || hasUserInteracted);

  /// Apakah baris petunjuk manual harus ditampilkan di atas tombol.
  bool get showGuidingHelper =>
      !hasConfirmedFix && !hasUserInteracted && !isLocatingUser;

  /// Menghasilkan state baru dengan mutasi data spesifik (GoF State Pattern).
  MapPickerOverlayState copyWith({
    bool? isLocatingUser,
    bool? isResolvingAddress,
    bool? hasGeocodeError,
    bool? hasConfirmedFix,
    bool? hasUserInteracted,
    Object? resolvedAddress = _sentinel,
  }) {
    return MapPickerOverlayState(
      isLocatingUser: isLocatingUser ?? this.isLocatingUser,
      isResolvingAddress: isResolvingAddress ?? this.isResolvingAddress,
      hasGeocodeError: hasGeocodeError ?? this.hasGeocodeError,
      hasConfirmedFix: hasConfirmedFix ?? this.hasConfirmedFix,
      hasUserInteracted: hasUserInteracted ?? this.hasUserInteracted,
      resolvedAddress: identical(resolvedAddress, _sentinel)
          ? this.resolvedAddress
          : resolvedAddress as String?,
    );
  }

  @override
  List<Object?> get props => [
        isLocatingUser,
        isResolvingAddress,
        hasGeocodeError,
        hasConfirmedFix,
        hasUserInteracted,
        resolvedAddress,
      ];
}
