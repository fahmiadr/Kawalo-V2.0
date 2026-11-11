import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';

/// Holds the user's theme preference; light until a saved choice is loaded.
///
/// Persistence is best-effort: a storage failure never blocks the switch.
class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit(this._storage) : super(ThemeMode.light);

  final SecureStorageService? _storage;

  Future<void> load() async {
    try {
      final saved = await _storage?.getThemeMode();
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (!isClosed && mode != null) emit(mode);
    } on Object catch (_) {}
  }

  Future<void> select(ThemeMode mode) async {
    emit(mode);
    try {
      await _storage?.saveThemeMode(mode.name);
    } on Object catch (_) {}
  }
}
