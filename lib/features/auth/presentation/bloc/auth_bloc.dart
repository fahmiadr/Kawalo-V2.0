import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.loginUseCase,
    this.switchGroupUseCase,
    this.authRepository,
    this.logoutUseCase,
  }) : super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SwitchGroupSubmitted>(_onSwitchGroupSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AvatarUpdated>(_onAvatarUpdated);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SessionExpiredRequested>(_onSessionExpiredRequested);
  }

  void _onSessionExpiredRequested(
    SessionExpiredRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(Unauthenticated(message: event.message));
  }

  final LoginUseCase loginUseCase;
  final SwitchGroupUseCase? switchGroupUseCase;
  final AuthRepository? authRepository;
  final UseCase<void, NoParams>? logoutUseCase;

  Future<AuthSessionEntity?> _resolveSession() async {
    final repo = authRepository;
    if (repo == null) return null;
    final res = await repo.getActiveSession();
    return res.getOrElse((_) => null);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await loginUseCase(
        LoginParams(email: event.email, password: event.password),
      );

      await result.fold(
        (failure) async => emit(
          AuthFailure(message: failure.message, statusCode: failure.statusCode),
        ),
        (user) async {
          if (user.groups.length > 1) {
            emit(GroupSelectionRequired(user: user));
          } else {
            final session = await _resolveSession();
            emit(Authenticated(user: user, session: session));
          }
        },
      );
    } on Object catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onSwitchGroupSubmitted(
    SwitchGroupSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (switchGroupUseCase == null) {
      emit(const AuthFailure(message: 'Layanan ganti grup tidak tersedia.'));
      return;
    }
    emit(const AuthLoading());
    try {
      final result = await switchGroupUseCase!(
        SwitchGroupParams(groupUid: event.groupUid),
      );

      await result.fold(
        (failure) async => emit(AuthFailure(message: failure.message)),
        (user) async {
          final session = await _resolveSession();
          emit(Authenticated(user: user, session: session));
        },
      );
    } on Object catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  void _onAvatarUpdated(AvatarUpdated event, Emitter<AuthState> emit) {
    final current = state;
    if (current is! Authenticated) return;
    emit(
      Authenticated(
        user: current.user.withAvatar(event.avatarUrl),
        session: current.session,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      if (logoutUseCase != null) {
        await logoutUseCase!(const NoParams());
      }
    } on Object catch (_) {
      // Best-effort logout
    } finally {
      emit(Unauthenticated(message: event.message));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final repo = authRepository;
    if (repo == null) {
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());
    try {
      final result = await repo.getCurrentUser();

      await result.fold((_) async => emit(const Unauthenticated()), (
        user,
      ) async {
        if (user != null) {
          if (user.groups.length > 1 && user.activeGroup == null) {
            emit(GroupSelectionRequired(user: user));
          } else {
            final session = await _resolveSession();
            emit(Authenticated(user: user, session: session));
          }
        } else {
          emit(const Unauthenticated());
        }
      });
    } on Object catch (_) {
      emit(const Unauthenticated());
    }
  }
}
