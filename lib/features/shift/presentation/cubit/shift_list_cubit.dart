import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_state.dart';

class ShiftListCubit extends Cubit<ShiftListState> {
  ShiftListCubit({required this.repository}) : super(const ShiftListInitial());

  final ShiftRepository repository;

  int _requestId = 0;

  /// Returns whether the load succeeded. With [silent] (pull-to-refresh or
  /// after a save) the list on screen stays while loading, and a failure keeps
  /// it instead of replacing it by an error.
  Future<bool> fetch({bool silent = false}) async {
    final id = ++_requestId;
    final keepPrevious = silent && state is ShiftListLoaded;
    if (!keepPrevious) emit(const ShiftListLoading());

    final result = await repository.getShifts();
    if (id != _requestId || isClosed) return false;

    final succeeded = result.fold(
      (failure) {
        if (!keepPrevious) emit(ShiftListError(failure.message));
        return false;
      },
      (shifts) {
        emit(ShiftListLoaded(shifts));
        return true;
      },
    );
    return succeeded;
  }
}
