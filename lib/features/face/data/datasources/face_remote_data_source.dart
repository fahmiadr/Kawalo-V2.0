import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/face/data/datasources/face_multipart.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';

/// `/v1/faces/*`. JSON is parsed by hand on purpose: the payloads are tiny and
/// the feature avoids generated code.
class FaceRemoteDataSource {
  const FaceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<FaceStatus> getStatus() async {
    final body = await apiClient.get('/v1/faces/status');
    final data = _map(body['data']);
    return FaceStatus(
      available: data['available'] == true,
      registered: data['registered'] == true,
      registeredAt: DateTime.tryParse(data['registered_at']?.toString() ?? ''),
      photoCount: (data['photo_count'] as num?)?.toInt() ?? 0,
      needsReregistration: data['needs_reregistration'] == true,
    );
  }

  Future<FaceRegistration> register(List<Uint8List> photos) async {
    final body = await postFaceMultipart(
      apiClient,
      '/v1/faces/register',
      // One `photos` part per photo, no `[]` suffix: the server matches the
      // exact field name.
      () => FormData()
        ..files.addAll([
          for (var i = 0; i < photos.length; i++)
            MapEntry(
              'photos',
              MultipartFile.fromBytes(
                photos[i],
                filename: 'face-${i + 1}.jpg',
                contentType: DioMediaType('image', 'jpeg'),
              ),
            ),
        ]),
    );
    final data = _map(body['data']);
    final rejected = data['rejected'];
    return FaceRegistration(
      photoCount: (data['photo_count'] as num?)?.toInt() ?? photos.length,
      rejectedCount: rejected is List ? rejected.length : 0,
    );
  }

  Future<bool> deleteMine() async {
    final body = await apiClient.delete('/v1/faces/me');
    return _map(body['data'])['deleted'] == true;
  }

  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
}
