import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';

void main() {
  group('NoInternetFailure Tests', () {
    test('default constructor uses standard no-internet message', () {
      const failure = NoInternetFailure();
      expect(
        failure.message,
        'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
      );
    });

    test('offlineNoStorage named constructor uses offlineNoStorageMessage', () {
      const failure = NoInternetFailure.offlineNoStorage();
      expect(failure.message, NoInternetFailure.offlineNoStorageMessage);
      expect(
        failure.message,
        'Perangkat sedang offline dan penyimpanan data tidak tersedia.',
      );
    });

    test('offlineNoStorage supports equatable value equality', () {
      const failure1 = NoInternetFailure.offlineNoStorage();
      const failure2 = NoInternetFailure.offlineNoStorage();

      expect(failure1, equals(failure2));
    });
  });

  group('AppConstants Tests', () {
    test('cacheRetentionDuration is 30 days', () {
      expect(AppConstants.cacheRetentionDuration, const Duration(days: 30));
    });
  });
}
