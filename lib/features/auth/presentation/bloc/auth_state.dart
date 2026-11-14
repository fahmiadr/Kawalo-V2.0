import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated({required this.user, this.session});
  final UserEntity user;
  final AuthSessionEntity? session;

  @override
  List<Object?> get props => [user, session];
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  const AuthFailure({required this.message, this.statusCode});
  final String message;

  /// HTTP status of the failed request (401 wrong credentials, 429 locked or
  /// rate limited), so the login screen can place the message.
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class GroupSelectionRequired extends AuthState {
  const GroupSelectionRequired({required this.user});
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}
