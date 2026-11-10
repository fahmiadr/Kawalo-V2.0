import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Emits the installed app version label (e.g. `1.0.0 (12)`), or `null` until
/// the platform answers or when it cannot be read.
class AppVersionCubit extends Cubit<String?> {
  AppVersionCubit() : super(null);

  Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (isClosed) return;
      emit('${info.version} (${info.buildNumber})');
    } on Object catch (_) {
      // The version line is informational; keep it hidden on failure.
    }
  }
}
