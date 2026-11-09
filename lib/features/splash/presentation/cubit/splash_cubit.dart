import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';

class SplashState extends Equatable {
  const SplashState({
    this.isReady = false,
    this.isOnboardingCompleted = false,
    this.isAuthenticated = false,
    this.isGroupSelectionRequired = false,
    this.user,
  });

  /// True once start-up checks finished, whether or not they succeeded.
  final bool isReady;
  final bool isOnboardingCompleted;
  final bool isAuthenticated;
  final bool isGroupSelectionRequired;
  final UserEntity? user;

  @override
  List<Object?> get props => [
    isReady,
    isOnboardingCompleted,
    isAuthenticated,
    isGroupSelectionRequired,
    user,
  ];
}

/// Resolves the inputs of the start-up routing decision: onboarding flag and
/// auth status.
///
/// Every failure degrades to "not completed / not authenticated" so the splash
/// can never get stuck.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    this.storage,
    this.authBloc,
    this.onInitialize,
    this.authTimeout = const Duration(seconds: 5),
  }) : super(const SplashState());

  final SecureStorageService? storage;

  /// When null (or when it fails) the stored access token decides instead.
  final AuthBloc? authBloc;
  final Future<void> Function()? onInitialize;
  final Duration authTimeout;

  Future<void> initialize() async {
    var isOnboardingCompleted = false;
    var isAuthenticated = false;
    var isGroupSelectionRequired = false;
    UserEntity? user;

    try {
      await onInitialize?.call();

      try {
        isOnboardingCompleted = await storage?.isOnboardingCompleted() ?? false;
      } on Object catch (_) {
        isOnboardingCompleted = false;
      }

      if (!isClosed) {
        try {
          final state = await _resolveAuthState();
          isAuthenticated = state is Authenticated;
          isGroupSelectionRequired = state is GroupSelectionRequired;
          if (state is Authenticated) {
            user = state.user;
          } else if (state is GroupSelectionRequired) {
            user = state.user;
          }
        } on Object catch (_) {
          isAuthenticated = await _hasStoredToken();
        }
      }
    } finally {
      if (!isClosed) {
        emit(
          SplashState(
            isReady: true,
            isOnboardingCompleted: isOnboardingCompleted,
            isAuthenticated: isAuthenticated,
            isGroupSelectionRequired: isGroupSelectionRequired,
            user: user,
          ),
        );
      }
    }
  }

  Future<AuthState> _resolveAuthState() {
    final bloc = authBloc;
    if (bloc == null) throw StateError('AuthBloc unavailable');
    final current = bloc.state;
    if (current is Authenticated || current is GroupSelectionRequired) {
      return Future.value(current);
    }
    bloc.add(const AuthCheckRequested());
    return bloc.stream
        .firstWhere((s) => s is! AuthLoading && s is! AuthInitial)
        .timeout(authTimeout, onTimeout: () => bloc.state);
  }

  Future<bool> _hasStoredToken() async {
    try {
      final token = await storage?.getAccessToken();
      return token != null && token.isNotEmpty;
    } on Object catch (_) {
      return false;
    }
  }
}
