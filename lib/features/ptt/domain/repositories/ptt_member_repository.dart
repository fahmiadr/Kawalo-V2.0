import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';

abstract interface class PttMemberRepository {
  /// Members connected to the active group's channel right now.
  Future<Either<Failure, List<PttMemberEntity>>> getMembers();
}
