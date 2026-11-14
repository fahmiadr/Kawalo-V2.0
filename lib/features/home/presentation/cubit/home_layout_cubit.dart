import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/domain/repositories/home_layout_repository.dart';

/// Beranda card layout of the signed-in user in the active group. Starts at
/// [HomeLayout.fallback] and never blocks: the cached copy is shown first,
/// then the server's.
class HomeLayoutCubit extends Cubit<HomeLayout> {
  HomeLayoutCubit({required this.repository}) : super(HomeLayout.fallback);

  final HomeLayoutRepository repository;

  String? _scope;

  /// Bumped by every load/save so a slow load cannot overwrite a newer save
  /// (or a layout of the previous group).
  int _generation = 0;

  static String? scopeOf(AuthSessionEntity? session) {
    final group = session?.groupUid;
    if (session == null || group == null || group.isEmpty) return null;
    return '${session.userId}@$group';
  }

  Future<void> load(AuthSessionEntity? session) async {
    final scope = scopeOf(session);
    _scope = scope;
    final generation = ++_generation;
    if (scope == null) return emit(HomeLayout.fallback);
    final cached = await repository.cached(scope);
    if (generation != _generation || isClosed) return;
    emit(cached ?? HomeLayout.fallback);
    final layout = await repository.load(scope);
    if (generation == _generation && !isClosed) emit(layout);
  }

  Future<void> save(HomeLayout layout) async {
    final generation = ++_generation;
    emit(layout);
    final scope = _scope;
    if (scope == null) return;
    final saved = await repository.save(scope, layout);
    if (generation == _generation && !isClosed) emit(saved);
  }
}
