import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/group/data/models/group_member_model.dart';

/// Kontrak sumber data jarak jauh (Remote Data Source) untuk modul grup.
abstract class GroupRemoteDataSource {
  /// Mengambil daftar anggota grup dari endpoint `/v1/groups/members`.
  Future<List<GroupMemberModel>> getMembers({
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [GroupRemoteDataSource] menggunakan [ApiClient].
class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  /// Membuat instance [GroupRemoteDataSourceImpl].
  const GroupRemoteDataSourceImpl({required this.apiClient});

  /// Klien HTTP API terpusat.
  final ApiClient apiClient;

  @override
  Future<List<GroupMemberModel>> getMembers({
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/groups/members',
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(GroupMemberModel.fromJson)
          .toList();
    }
    return const [];
  }
}
