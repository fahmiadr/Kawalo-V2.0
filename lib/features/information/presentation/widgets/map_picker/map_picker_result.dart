/// @docImport 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/app_map_picker_dialog.dart';
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Hasil pemilihan koordinat pada [AppMapPickerDialog].
///
/// Objek pembawa data (*value object*) yang bersifat *immutable* dan
/// mengimplementasikan [Equatable] untuk memfasilitasi perbandingan nilai
/// kesetaraan struktural koordinat dan alamat.
///
/// Dihasilkan oleh [AppMapPickerDialog.show] saat pengguna mengonfirmasi
/// pemilihan titik lokasi.
@immutable
class AppMapPickerResult extends Equatable {
  /// Membuat instans [AppMapPickerResult].
  const AppMapPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  /// Garis lintang (Latitude) koordinat yang dipilih.
  final double latitude;

  /// Garis bujur (Longitude) koordinat yang dipilih.
  final double longitude;

  /// Alamat jalan representatif hasil proses *reverse geocoding*.
  ///
  /// Bernilai `null` jika reverse geocoding belum selesai, tidak berhasil
  /// menemukan alamat, atau layanan reverse geocoding tidak disediakan.
  final String? address;

  @override
  List<Object?> get props => [latitude, longitude, address];
}
