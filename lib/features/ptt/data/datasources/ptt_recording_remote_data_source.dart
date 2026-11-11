import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_recording_model.dart';

abstract interface class PttRecordingRemoteDataSource {
  Future<PttRecordingPageModel> getRecordings({String? before, int? limit});

  /// Saves the audio of [id] to [savePath].
  Future<void> downloadAudio(String id, String savePath);

  Future<void> deleteRecording(String id);
}

class PttRecordingRemoteDataSourceImpl implements PttRecordingRemoteDataSource {
  const PttRecordingRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<PttRecordingPageModel> getRecordings({
    String? before,
    int? limit,
  }) async {
    final response = await apiClient.get(
      '/v1/ptt/recordings',
      queryParameters: {'before': ?before, 'limit': ?limit},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return PttRecordingPageModel.fromJson(data);
    }
    throw const FormatException('Format riwayat rekaman tidak valid.');
  }

  /// Goes through `ApiClient.dio`, so the access token is attached and an
  /// expired one (401) is refreshed and the download retried by the same
  /// interceptor as every other request.
  @override
  Future<void> downloadAudio(String id, String savePath) async {
    try {
      await apiClient.dio.download('/v1/ptt/recordings/$id/audio', savePath);
    } on DioException catch (e) {
      final appException = NetworkErrorHandler.handleDioError(e);
      if (appException is NoInternetException) {
        apiClient.onConnectionFailed?.call();
      }
      throw appException;
    }
  }

  @override
  Future<void> deleteRecording(String id) async {
    await apiClient.delete('/v1/ptt/recordings/$id');
  }
}
