import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/file_download_state.dart';
import 'package:kawalo_mobile/features/information/presentation/utils/attachment_file_info.dart';
import 'package:path_provider/path_provider.dart';

/// Mengelola unduhan berkas lampiran informasi.
class FileDownloadCubit extends Cubit<FileDownloadState> {
  FileDownloadCubit(
    this._dio, {
    Future<Directory> Function() documentsDirectory =
        getApplicationDocumentsDirectory,
  }) : _documentsDirectory = documentsDirectory,
       super(const FileDownloadIdle());

  final Dio _dio;
  final Future<Directory> Function() _documentsDirectory;

  Future<void> download(String file) async {
    if (state is FileDownloadInProgress) return;

    // Attachments are hosted by the upload endpoint; anything else (a stale
    // local path) has nothing to fetch.
    if (!file.startsWith('http://') && !file.startsWith('https://')) {
      emit(const FileDownloadFailure('Berkas ini tidak dapat diunduh.'));
      return;
    }

    emit(const FileDownloadInProgress(0.1));

    try {
      final fileName = attachmentFileName(file);

      String savePath;
      try {
        final dir = await _documentsDirectory();
        savePath = '${dir.path}/$fileName';
      } on Object catch (_) {
        savePath = '/downloads/$fileName';
      }

      await _dio.download(
        file,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && !isClosed) {
            emit(FileDownloadInProgress(received / total));
          }
        },
      );

      if (!isClosed) emit(const FileDownloadDone());
    } on Object catch (e) {
      if (!isClosed) emit(FileDownloadFailure('Gagal mengunduh berkas: $e'));
    }
  }
}
