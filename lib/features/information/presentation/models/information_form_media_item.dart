import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';

/// Model item media (foto atau dokumen) pada formulir informasi.
///
/// Mendukung berkas lokal (hasil jepretan kamera / pemilihan galeri / dokumen)
/// maupun berkas remote dari data awal edit postingan.
@immutable
class InformationFormMediaItem extends Equatable {
  /// Membuat instance [InformationFormMediaItem].
  const InformationFormMediaItem({
    required this.id,
    required this.name,
    this.path,
    this.bytes,
    this.remoteUrl,
    this.isLocal = true,
    this.fileSize,
    this.isLoading = false,
  });

  /// Factory untuk membuat item dari [AppMediaFile] lokal.
  factory InformationFormMediaItem.fromAppMediaFile(
    AppMediaFile file, {
    String? id,
  }) {
    return InformationFormMediaItem(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: file.name,
      path: file.path,
      bytes: file.bytes,
      fileSize: file.sizeInBytes,
    );
  }

  /// Factory untuk membuat item dari URL remote yang sudah ada.
  factory InformationFormMediaItem.fromRemoteUrl(
    String url, {
    String? id,
    String? name,
  }) {
    final fileName =
        name ?? url.split('/').lastOrNull?.split('?').firstOrNull ?? 'Berkas';
    return InformationFormMediaItem(
      id: id ?? url,
      name: fileName,
      remoteUrl: url,
      isLocal: false,
    );
  }

  /// Factory untuk membuat item penampung sementara ketika foto sedang
  /// dimuat atau dikompresi.
  factory InformationFormMediaItem.loading({String? id, String? name}) {
    return InformationFormMediaItem(
      id: id ?? 'temp_loading_${DateTime.now().microsecondsSinceEpoch}',
      name: name ?? 'Memuat foto...',
      isLoading: true,
    );
  }

  /// Identifier unik item media di dalam form.
  final String id;

  /// Nama berkas atau judul representatif.
  final String name;

  /// Jalur berkas di penyimpanan lokal perangkat.
  final String? path;

  /// Byte berkas jika disimpan dalam memori.
  final Uint8List? bytes;

  /// URL remote jika berkas sudah tersimpan di server.
  final String? remoteUrl;

  /// Apakah berkas merupakan berkas lokal perangkat.
  final bool isLocal;

  /// Ukuran berkas dalam bytes (opsional).
  final int? fileSize;

  /// Menandakan apakah foto sedang dalam proses pemuatan atau kompresi.
  final bool isLoading;

  /// Sumber tampilan visual atau tautan utama.
  String get displaySource => isLocal ? (path ?? name) : (remoteUrl ?? name);

  /// Membuat salinan objek dengan field yang diperbarui.
  InformationFormMediaItem copyWith({
    String? id,
    String? name,
    String? path,
    Uint8List? bytes,
    String? remoteUrl,
    bool? isLocal,
    int? fileSize,
    bool? isLoading,
  }) {
    return InformationFormMediaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isLocal: isLocal ?? this.isLocal,
      fileSize: fileSize ?? this.fileSize,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    path,
    bytes,
    remoteUrl,
    isLocal,
    fileSize,
    isLoading,
  ];
}
