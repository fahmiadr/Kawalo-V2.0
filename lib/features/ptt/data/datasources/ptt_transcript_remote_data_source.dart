import 'package:kawalo_mobile/core/network/api_client.dart';

abstract interface class PttTranscriptRemoteDataSource {
  /// `PUT /v1/ptt/recordings/by-request/{requestId}/transcript`. Throws the
  /// `ApiClient` exceptions (a `ServerException` with 404 means the recording
  /// is not written yet).
  Future<void> putTranscript({
    required String requestId,
    required String status,
    String? text,
    String? locale,
  });
}

class PttTranscriptRemoteDataSourceImpl
    implements PttTranscriptRemoteDataSource {
  const PttTranscriptRemoteDataSourceImpl({required this.apiClient});

  /// Server limit for the transcript text, in characters.
  static const maxTextLength = 2000;

  final ApiClient apiClient;

  @override
  Future<void> putTranscript({
    required String requestId,
    required String status,
    String? text,
    String? locale,
  }) async {
    await apiClient.put(
      '/v1/ptt/recordings/by-request/${Uri.encodeComponent(requestId)}/transcript',
      body: transcriptBody(status: status, text: text, locale: locale),
    );
  }

  /// Only `ok` carries text and locale. Text is cut by code point so a
  /// surrogate pair is never split.
  static Map<String, dynamic> transcriptBody({
    required String status,
    String? text,
    String? locale,
  }) {
    final trimmed = text?.trim() ?? '';
    if (status != 'ok') return {'status': status};
    // The server rejects `ok` without text; `failed` still gets it transcribed.
    if (trimmed.isEmpty) return {'status': 'failed'};
    final runes = trimmed.runes;
    return {
      'status': status,
      'text': runes.length > maxTextLength
          ? String.fromCharCodes(runes.take(maxTextLength)).trim()
          : trimmed,
      'locale': ?locale,
    };
  }
}
