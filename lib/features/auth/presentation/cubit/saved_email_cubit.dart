import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';

/// Holds the last signed-in email so the login form can pre-fill it.
///
/// Emits nothing when there is no saved email or storage fails; the pre-fill
/// is best-effort.
class SavedEmailCubit extends Cubit<String?> {
  SavedEmailCubit(this._storage) : super(null);

  final SecureStorageService? _storage;

  Future<void> load() async {
    try {
      final email = await _storage?.getLastEmail();
      if (!isClosed && email != null && email.isNotEmpty) emit(email);
    } on Object catch (_) {}
  }
}
