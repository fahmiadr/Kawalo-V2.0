import 'package:kawalo_mobile/features/ptt/data/models/ptt_member_model.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';

abstract final class PttMemberMapper {
  const PttMemberMapper._();

  static PttMemberEntity toEntity(PttMemberModel model) => PttMemberEntity(
    userId: model.userId,
    name: model.name,
    role: model.role,
    avatarUrl: model.avatarUrl,
    speaking: model.speaking,
  );
}
