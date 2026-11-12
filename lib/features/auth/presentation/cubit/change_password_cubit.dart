import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Client-side rules of the change-password form. Passwords are compared and
/// sent trimmed, like the server does.
abstract final class ChangePasswordRules {
  const ChangePasswordRules._();

  static const int minLength = 8;
  // Matches the API: the legacy tkuser.Password column is VARCHAR(64).
  static const int maxLength = 64;

  static String? newPassword(String value, String current) {
    final password = value.trim();
    if (password.isEmpty) return null;
    if (password.length < minLength) {
      return 'Password baru minimal $minLength karakter.';
    }
    if (password.length > maxLength) {
      return 'Password baru maksimal $maxLength karakter.';
    }
    if (password == current.trim()) {
      return 'Password baru harus berbeda dari password saat ini.';
    }
    return null;
  }

  static String? repeat(String value, String newValue) {
    if (value.isEmpty || value.trim() == newValue.trim()) return null;
    return 'Ulangi password tidak sama dengan password baru.';
  }

  static bool isValid({
    required String current,
    required String newValue,
    required String repeatValue,
  }) =>
      current.trim().isNotEmpty &&
      newValue.trim().isNotEmpty &&
      newPassword(newValue, current) == null &&
      repeat(repeatValue, newValue) == null &&
      repeatValue.isNotEmpty;
}

enum ChangePasswordStatus { idle, saving, success, wrongCurrent, failed }

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.message,
  });

  final ChangePasswordStatus status;
  final String? message;

  @override
  List<Object?> get props => [status, message];
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._repository) : super(const ChangePasswordState());

  /// The backend answers 403 with this code for a wrong current password, on
  /// purpose: a 401 would make the auth interceptor treat it as session expiry.
  static const String wrongPasswordCode = 'AUTH_INVALID_CREDENTIALS';

  final AuthRepository _repository;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.status == ChangePasswordStatus.saving) return;
    emit(const ChangePasswordState(status: ChangePasswordStatus.saving));
    final result = await _repository.changePassword(
      currentPassword: currentPassword.trim(),
      newPassword: newPassword.trim(),
    );
    if (isClosed) return;
    emit(
      result.fold(
        (failure) =>
            failure.statusCode == 403 && failure.errorCode == wrongPasswordCode
            ? ChangePasswordState(
                status: ChangePasswordStatus.wrongCurrent,
                message: failure.message.isEmpty
                    ? 'Password saat ini salah.'
                    : failure.message,
              )
            : ChangePasswordState(
                status: ChangePasswordStatus.failed,
                message: failure.message,
              ),
        (_) => const ChangePasswordState(status: ChangePasswordStatus.success),
      ),
    );
  }
}
