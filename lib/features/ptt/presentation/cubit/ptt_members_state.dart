import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';

class PttMembersState extends Equatable {
  const PttMembersState({
    this.members = const [],
    this.isLoading = true,
    this.failed = false,
  });

  final List<PttMemberEntity> members;

  /// No answer yet. Re-fetches keep the previous list on screen instead.
  final bool isLoading;

  /// The last fetch failed; [members] still holds the last known list.
  final bool failed;

  PttMembersState copyWith({
    List<PttMemberEntity>? members,
    bool? isLoading,
    bool? failed,
  }) {
    return PttMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      failed: failed ?? this.failed,
    );
  }

  @override
  List<Object?> get props => [members, isLoading, failed];
}
