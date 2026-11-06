import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/get_active_session_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.loginUseCase,
    this.switchGroupUseCase,
    this.getCurrentUserUseCase,
    this.logoutUseCase,
    this.getActiveSessionUseCase,
  }) : super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SwitchGroupSubmitted>(_onSwitchGroupSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
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
  final GetCurrentUserUseCase? getCurrentUserUseCase;
  final UseCase<void, NoParams>? logoutUseCase;
  final GetActiveSessionUseCase? getActiveSessionUseCase;

  Future<AuthSessionEntity?> _resolveSession() async {
    if (getActiveSessionUseCase == null) return null;
    final res = await getActiveSessionUseCase!(const NoParams());
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
        (failure) async => emit(AuthFailure(message: failure.message)),
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
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (getCurrentUserUseCase == null) {
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());
    try {
      final result = await getCurrentUserUseCase!(const NoParams());

      await result.fold(
        (_) async => emit(const Unauthenticated()),
        (user) async {
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
        },
      );
    } on Object catch (_) {
      emit(const Unauthenticated());
    }
  }
}
