import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_member_repository.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// Who is online in the channel. The native layer only reports a count, so the
/// list is fetched from the API whenever the channel (re)connects or the count
/// changes. Lives with the channel screen, not at app level.
class PttMembersCubit extends Cubit<PttMembersState> {
  PttMembersCubit({
    required PttMemberRepository repository,
    required PttCubit ptt,
    this.debounce = const Duration(milliseconds: 500),
  }) : _repository = repository,
       super(const PttMembersState()) {
    _lastKey = _keyOf(ptt.state);
    _subscription = ptt.stream.listen(_onPttState);
    if (_lastKey.connected) unawaited(_fetch());
  }

  final PttMemberRepository _repository;
  final Duration debounce;

  late final StreamSubscription<PttState> _subscription;
  late ({bool connected, int? count}) _lastKey;
  Timer? _timer;

  /// Bumped by every fetch so a slow response of a superseded request cannot
  /// overwrite a newer list.
  int _generation = 0;

  static ({bool connected, int? count}) _keyOf(PttState s) => (
    connected: s.channel.connectionStatus == PttConnectionStatus.connected,
    count: s.channel.memberCount,
  );

  void _onPttState(PttState pttState) {
    final key = _keyOf(pttState);
    if (key == _lastKey) return;
    _lastKey = key;
    _timer?.cancel();
    if (key.connected) _timer = Timer(debounce, () => unawaited(_fetch()));
  }

  Future<void> retry() {
    emit(state.copyWith(failed: false));
    return _fetch();
  }

  Future<void> _fetch() async {
    final generation = ++_generation;
    final result = await _repository.getMembers();
    if (generation != _generation || isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(isLoading: false, failed: true)),
      (members) => emit(PttMembersState(members: members, isLoading: false)),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    unawaited(_subscription.cancel());
    return super.close();
  }
}
