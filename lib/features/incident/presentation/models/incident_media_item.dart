import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';

/// Upload lifecycle of a photo attached to an incident report or reply.
enum IncidentUploadStatus {
  /// Not uploaded yet (or queued behind the parallel upload limit).
  pending,

  /// Upload in flight; see [IncidentMediaItem.uploadProgress].
  uploading,

  /// Upload failed; see [IncidentMediaItem.uploadError]. Can be retried.
  failed,

  /// Uploaded; [IncidentMediaItem.remoteUrl] holds the public URL.
  done,
}

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
    this.uploadStatus = IncidentUploadStatus.pending,
    this.uploadProgress = 0,
    this.uploadError,
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
      uploadStatus: IncidentUploadStatus.done,
      uploadProgress: 1,
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

  /// Status unggah foto.
  final IncidentUploadStatus uploadStatus;

  /// Progres unggah antara 0 dan 1.
  final double uploadProgress;

  /// Pesan galat unggah terakhir (Bahasa Indonesia) saat [uploadStatus] gagal.
  final String? uploadError;

  /// Sumber visual efektif foto (jalur lokal atau URL remote).
  String get displaySource => path ?? remoteUrl ?? '';

  /// Apakah foto sudah punya URL hasil unggah.
  bool get isUploaded =>
      uploadStatus == IncidentUploadStatus.done &&
      remoteUrl != null &&
      remoteUrl!.isNotEmpty;

  /// Apakah foto sedang diunggah.
  bool get isUploading => uploadStatus == IncidentUploadStatus.uploading;

  /// Apakah foto masih perlu diunggah (menunggu atau gagal).
  bool get needsUpload => !isUploaded && !isUploading;

  /// Salinan dengan status unggah baru; [remoteUrl] hanya diisi saat selesai.
  IncidentMediaItem withUpload({
    required IncidentUploadStatus status,
    double progress = 0,
    String? error,
    String? remoteUrl,
  }) {
    return IncidentMediaItem(
      id: id,
      name: name,
      path: path,
      bytes: bytes,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isLocal: isLocal,
      uploadStatus: status,
      uploadProgress: progress,
      uploadError: error,
    );
  }

  /// Berkas sumber yang dikirim ke `UploadRepository`.
  AppMediaFile toMediaFile() =>
      AppMediaFile(name: name, path: path, bytes: bytes);

  @override
  List<Object?> get props => [
    id,
    name,
    path,
    bytes,
    remoteUrl,
    isLocal,
    uploadStatus,
    uploadProgress,
    uploadError,
  ];
}
