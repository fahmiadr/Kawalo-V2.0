import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';

/// Cubit pengelola sesi pengguna aktif di tingkat aplikasi (Shared App State).
///
/// Menyediakan representasi sesi pengguna ([AuthSessionEntity]) yang bersih,
/// immutable, dan reaktif ke seluruh fitur aplikasi tanpa mengikat fitur-fitur
/// tersebut ke BLoC autentikasi internal (AuthBloc).
class UserSessionCubit extends Cubit<AuthSessionEntity?> {
  /// Membuat instance [UserSessionCubit].
  UserSessionCubit([super.initialState]);

  /// Memperbarui data sesi pengguna aktif.
  void updateSession(AuthSessionEntity? session) {
    if (state != session) {
      emit(session);
    }
  }

  /// Mengosongkan sesi pengguna aktif (misal saat logout).
  void clearSession() {
    if (state != null) {
      emit(null);
    }
  }

  /// Menandakan apakah ada pengguna yang sedang terautentikasi aktif.
  bool get isAuthenticated => state != null;

  /// Role aktif pengguna pada sesi ini (misal: 'ADMIN', 'GUARD').
  String? get userRole => state?.role;

  /// Alamat email resmi pengguna aktif.
  String? get userEmail => state?.email;

  /// ID unik pengguna aktif.
  String? get userId => state?.userId;

  /// Nama lengkap pengguna aktif.
  String? get userName => state?.name;
}
