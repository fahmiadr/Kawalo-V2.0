import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';

class BackgroundAccessState extends Equatable {
  const BackgroundAccessState({this.status, this.requesting = false});

  /// Null until loaded, and when there is no native side (iOS, tests).
  final BackgroundAccessStatus? status;
  final bool requesting;

  bool get shouldPrompt => status?.shouldPrompt ?? false;

  @override
  List<Object?> get props => [status, requesting];
}

class BackgroundAccessCubit extends Cubit<BackgroundAccessState> {
  BackgroundAccessCubit({
    BackgroundAccessService service = const BackgroundAccessService(),
  }) : _service = service,
       super(const BackgroundAccessState());

  final BackgroundAccessService _service;

  Future<void> load() async {
    try {
      final status = await _service.status();
      if (!isClosed) emit(BackgroundAccessState(status: status));
    } on Object catch (_) {
      if (!isClosed) emit(const BackgroundAccessState());
    }
  }

  /// Shows the system dialog of every askable item in turn. One refusal does
  /// not stop the others.
  Future<void> requestAll() async {
    final status = state.status;
    if (status == null || state.requesting) return;
    emit(BackgroundAccessState(status: status, requesting: true));
    for (final item in BackgroundAccessItem.values) {
      if (status.grants[item] != BackgroundAccessGrant.askable) continue;
      try {
        await _service.request(item);
      } on Object catch (_) {}
    }
    await load();
  }

  Future<void> skip() async {
    try {
      await _service.skip();
    } on Object catch (_) {}
  }
}
