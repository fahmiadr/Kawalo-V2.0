import 'package:equatable/equatable.dart';

/// State proses unduh satu berkas lampiran.
sealed class FileDownloadState extends Equatable {
  const FileDownloadState();

  @override
  List<Object?> get props => const [];
}

/// Belum ada unduhan berjalan.
final class FileDownloadIdle extends FileDownloadState {
  const FileDownloadIdle();
}

/// Unduhan berjalan; [progress] bernilai 0..1.
final class FileDownloadInProgress extends FileDownloadState {
  const FileDownloadInProgress(this.progress);

  final double progress;

  @override
  List<Object?> get props => [progress];
}

/// Unduhan selesai.
final class FileDownloadDone extends FileDownloadState {
  const FileDownloadDone();
}

/// Unduhan gagal dengan [message] siap tampil ke pengguna.
final class FileDownloadFailure extends FileDownloadState {
  const FileDownloadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
