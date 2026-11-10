import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/upload/image_compressor.dart';
import 'package:kawalo_mobile/core/upload/upload_remote_data_source.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';

class UploadRepositoryImpl implements UploadRepository {
  const UploadRepositoryImpl({
    required UploadRemoteDataSource remoteDataSource,
    ImageCompressor compressor = const ImageCompressor(),
    NetworkInfo? networkInfo,
  }) : _remote = remoteDataSource,
       _compressor = compressor,
       _networkInfo = networkInfo;

  static const int maxDocumentBytes = 10 * 1024 * 1024;
  static const Map<String, String> documentContentTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
  };
  static const String unsupportedDocumentMessage =
      'Format dokumen tidak didukung. Gunakan PDF, DOC, DOCX, XLS, XLSX, '
      'atau TXT.';
  static const String documentTooLargeMessage =
      'Ukuran dokumen melebihi 10 MB.';
  static const String unreadableDocumentMessage =
      'Dokumen tidak dapat dibaca. Pilih dokumen lain.';

  final UploadRemoteDataSource _remote;
  final ImageCompressor _compressor;
  final NetworkInfo? _networkInfo;

  @override
  Future<Either<Failure, String>> uploadImage(
    AppMediaFile file, {
    UploadProgress? onProgress,
  }) async {
    if (!await _isOnline()) return const Left(NoInternetFailure());
    final compressed = await _compressor.compress(file);
    return await compressed.fold(
      (failure) async => Left(failure),
      (bytes) => _send(
        bytes: bytes,
        filename: '${UploadRemoteDataSource.newUuid()}.webp',
        kind: UploadKind.image,
        contentType: DioMediaType('image', 'webp'),
        onProgress: onProgress,
      ),
    );
  }

  @override
  Future<Either<Failure, String>> uploadDocument(
    AppMediaFile file, {
    UploadProgress? onProgress,
  }) async {
    final ext = (file.extension ?? _extensionOf(file.name)).toLowerCase();
    final contentType = documentContentTypes[ext];
    if (contentType == null) {
      return const Left(ValidationFailure(unsupportedDocumentMessage));
    }
    final declared = file.sizeInBytes ?? file.bytes?.length;
    if (declared != null && declared > maxDocumentBytes) {
      return const Left(ValidationFailure(documentTooLargeMessage));
    }
    final Uint8List bytes;
    try {
      bytes = file.bytes ?? await File(file.path ?? '').readAsBytes();
    } on Object catch (_) {
      return const Left(ValidationFailure(unreadableDocumentMessage));
    }
    if (bytes.length > maxDocumentBytes) {
      return const Left(ValidationFailure(documentTooLargeMessage));
    }
    if (!await _isOnline()) return const Left(NoInternetFailure());
    return await _send(
      bytes: bytes,
      filename: '${UploadRemoteDataSource.newUuid()}.$ext',
      kind: UploadKind.document,
      contentType: DioMediaType.parse(contentType),
      onProgress: onProgress,
    );
  }

  Future<bool> _isOnline() async => await (_networkInfo?.isConnected ?? true);

  Future<Either<Failure, String>> _send({
    required Uint8List bytes,
    required String filename,
    required UploadKind kind,
    required DioMediaType contentType,
    required UploadProgress? onProgress,
  }) async {
    try {
      final url = await _remote.upload(
        bytes: bytes,
        filename: filename,
        kind: kind,
        contentType: contentType,
        onProgress: onProgress,
      );
      return Right(url);
    } on RequestCancelledException {
      return const Left(RequestCancelledFailure());
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1);
  }
}
