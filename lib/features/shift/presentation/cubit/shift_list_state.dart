import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';

sealed class ShiftListState extends Equatable {
  const ShiftListState();

  @override
  List<Object?> get props => const [];
}

class ShiftListInitial extends ShiftListState {
  const ShiftListInitial();
}

class ShiftListLoading extends ShiftListState {
  const ShiftListLoading();
}

/// [shifts] is empty when the group has no shift yet.
class ShiftListLoaded extends ShiftListState {
  const ShiftListLoaded(this.shifts);

  final List<ShiftEntity> shifts;

  @override
  List<Object?> get props => [shifts];
}

class ShiftListError extends ShiftListState {
  const ShiftListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
