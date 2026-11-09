import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';

/// Model item media presentasi untuk foto lampiran laporan insiden atau
/// balasan thread.
///
/// Bertindak sebagai model UI murni yang terisolasi di layer Presentation,
/// mendukung foto lokal hasil jepretan kamera maupun tautan remote URL.
@immutable
class IncidentMediaItem extends Equatable {
  /// Membuat instance [IncidentMediaItem].
  const IncidentMediaItem({
    required this.id,
    required this.name,
    this.path,
    this.bytes,
    this.remoteUrl,
    this.isLocal = true,
  });

  /// Factory untuk membuat item dari [AppMediaFile] jepretan kamera multi-shot.
  factory IncidentMediaItem.fromAppMediaFile(AppMediaFile file, {String? id}) {
    return IncidentMediaItem(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: file.name,
      path: file.path,
      bytes: file.bytes,
    );
  }

  /// Factory untuk membuat item dari URL remote yang sudah ada.
  factory IncidentMediaItem.fromRemoteUrl(
    String url, {
    String? id,
    String? name,
  }) {
    final fileName =
        name ?? url.split('/').lastOrNull?.split('?').firstOrNull ?? 'foto.jpg';
    return IncidentMediaItem(
      id: id ?? url,
      name: fileName,
      remoteUrl: url,
      isLocal: false,
    );
  }

  /// ID unik item media lokal/remote.
  final String id;

  /// Nama berkas foto.
  final String name;

  /// Jalur berkas di penyimpanan lokal perangkat.
  final String? path;

  /// Bita biner foto dalam memori.
  final Uint8List? bytes;

  /// URL remote foto jika telah diunggah atau dari server.
  final String? remoteUrl;

  /// Penanda apakah foto berasal dari penyimpanan lokal.
  final bool isLocal;

  /// Sumber visual efektif foto (jalur lokal, URL remote, atau URL kanonikal).
  String get displaySource => path ?? remoteUrl ?? toPhotoUrl();

  /// Menyelesaikan media menjadi string URL foto kanonikal untuk payload JSON
  /// API.
  String toPhotoUrl() {
    if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      return remoteUrl!;
    }
    return 'https://cdn.kawalo.internal/incidents/photos/$name';
  }

  @override
  List<Object?> get props => [id, name, path, bytes, remoteUrl, isLocal];
}
