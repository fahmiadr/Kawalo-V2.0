import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

sealed class PersonnelState extends Equatable {
  const PersonnelState();

  @override
  List<Object?> get props => const [];
}

class PersonnelInitial extends PersonnelState {
  const PersonnelInitial();
}

class PersonnelLoading extends PersonnelState {
  const PersonnelLoading();
}

/// [members] is empty when the active group has no joined member.
class PersonnelLoaded extends PersonnelState {
  const PersonnelLoaded(this.members);

  final List<GroupMemberEntity> members;

  @override
  List<Object?> get props => [members];
}

class PersonnelError extends PersonnelState {
  const PersonnelError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
