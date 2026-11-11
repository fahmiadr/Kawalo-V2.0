import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_member_model.dart';

abstract interface class PttMemberRemoteDataSource {
  Future<List<PttMemberModel>> getMembers();
}

class PttMemberRemoteDataSourceImpl implements PttMemberRemoteDataSource {
  const PttMemberRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<PttMemberModel>> getMembers() async {
    final response = await apiClient.get('/v1/ptt/members');
    final data = response['data'];
    final members = data is Map<String, dynamic> ? data['members'] : null;
    if (members is List) {
      return [
        for (final m in members)
          if (m is Map<String, dynamic>) PttMemberModel.fromJson(m),
      ];
    }
    throw const FormatException('Format daftar anggota PTT tidak valid.');
  }
}
