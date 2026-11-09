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
  const AuthFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class GroupSelectionRequired extends AuthState {
  const GroupSelectionRequired({required this.user});
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}
