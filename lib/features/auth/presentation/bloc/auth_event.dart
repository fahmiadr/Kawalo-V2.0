import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class SwitchGroupSubmitted extends AuthEvent {
  const SwitchGroupSubmitted({required this.groupUid});
  final String groupUid;

  @override
  List<Object?> get props => [groupUid];
}

class SessionExpiredRequested extends AuthEvent {
  const SessionExpiredRequested({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}
