import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';

/// Helper terpusat untuk menampilkan umpan balik (feedback) ramah pengguna
/// Material 3 atas hasil pemanggilan data (fetch, search, filter, refresh).
abstract final class AppFetchFeedback {
  const AppFetchFeedback._();

  /// Menampilkan snackbar umpan balik berdasarkan [result] operasi fetch.
  ///
  /// Menjamin bahwa ketika data disajikan dari cache lokal (offline atau
  /// kendala jaringan), pengguna menerima informasi yang akurat dan solutif.
  static void show(
    BuildContext context, {
    required AppFetchResult result,
    required bool hasData,
    String? successMessage,
    String? offlineSuccessMessage,
  }) {
    if (result == AppFetchResult.cancelled ||
        result == AppFetchResult.failure) {
      return;
    }

    if (result == AppFetchResult.success) {
      if (successMessage != null && successMessage.isNotEmpty) {
        AppSnackbar.show(context, message: successMessage);
      }
      return;
    }

    if (result == AppFetchResult.cachedFallback) {
      final isOffline = context.read<ConnectivityCubit?>()?.isOffline ?? false;

      if (isOffline) {
        AppSnackbar.show(
          context,
          message:
              offlineSuccessMessage ??
              (hasData
                  ? 'Tidak ada koneksi internet. Menampilkan data tersimpan.'
                  : 'Tidak ada koneksi internet. Belum ada data tersimpan.'),
        );
      } else {
        AppSnackbar.show(
          context,
          message: hasData
              ? 'Layanan belum dapat merespons. Menampilkan data tersimpan.'
              : 'Layanan belum dapat merespons. Belum ada data tersimpan.',
        );
      }
    }
  }
}
