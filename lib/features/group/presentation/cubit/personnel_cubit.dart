import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_state.dart';

/// Read-only list of the active group's members.
class PersonnelCubit extends Cubit<PersonnelState> {
  PersonnelCubit({required this.repository}) : super(const PersonnelInitial());

  final GroupRepository repository;

  int _requestId = 0;

  /// Loads the members and returns whether it succeeded. With [silent]
  /// (pull-to-refresh) the content on screen stays while loading, and a
  /// failure keeps it instead of replacing it by an error.
  Future<bool> fetch({bool silent = false}) async {
    final id = ++_requestId;
    final keepPrevious = silent && state is PersonnelLoaded;
    if (!keepPrevious) emit(const PersonnelLoading());

    final result = await repository.getMembers();
    if (id != _requestId || isClosed) return false;

    final succeeded = result.fold(
      (failure) {
        if (!keepPrevious) emit(PersonnelError(failure.message));
        return false;
      },
      (members) {
        emit(PersonnelLoaded(members));
        return true;
      },
    );
    return succeeded;
  }
}
