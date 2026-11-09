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

    emit(const FileDownloadInProgress(0.1));

    try {
      final isNetwork =
          file.startsWith('http://') || file.startsWith('https://');
      final fileName = attachmentFileName(file);

      String savePath;
      try {
        final dir = await _documentsDirectory();
        savePath = '${dir.path}/$fileName';
      } on Object catch (_) {
        savePath = '/downloads/$fileName';
      }

      if (isNetwork) {
        await _dio.download(
          file,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0 && !isClosed) {
              emit(FileDownloadInProgress(received / total));
            }
          },
        );
      } else {
        // Local paths and mock links have nothing to fetch; simulate progress.
        for (var step = 1; step <= 5; step++) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          if (!isClosed) emit(FileDownloadInProgress(step / 5));
        }
      }

      if (!isClosed) emit(const FileDownloadDone());
    } on Object catch (e) {
      if (!isClosed) emit(FileDownloadFailure('Gagal mengunduh berkas: $e'));
    }
  }
}
