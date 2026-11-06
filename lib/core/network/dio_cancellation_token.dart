import 'package:dio/dio.dart' as dio;
import 'package:kawalo_mobile/core/network/cancellation_token.dart';

/// Implementasi [AppCancellationToken] menggunakan adapter [dio.CancelToken].
///
/// Bertindak sebagai Adapter di layer infrastruktur/jaringan untuk menghubungkan
/// kontrak pembatalan domain dengan engine HTTP Dio.
class DioCancellationToken implements AppCancellationToken {
  /// Membuat instance [DioCancellationToken] baru atau membungkus [dioToken].
  DioCancellationToken([dio.CancelToken? dioToken])
      : dioToken = dioToken ?? dio.CancelToken();

  /// Instance [dio.CancelToken] internal yang dikelola.
  final dio.CancelToken dioToken;

  @override
  bool get isCancelled => dioToken.isCancelled;

  @override
  String? get cancelReason => dioToken.cancelError?.message;

  @override
  void cancel([String? reason]) {
    dioToken.cancel(reason);
  }
}

/// Ekstensi untuk mengonversi [AppCancellationToken] ke [dio.CancelToken].
extension AppCancellationTokenDioExt on AppCancellationToken {
  /// Mengambil atau mengonversi ke [dio.CancelToken].
  dio.CancelToken toDio() {
    if (this is DioCancellationToken) {
      return (this as DioCancellationToken).dioToken;
    }
    final token = dio.CancelToken();
    return token;
  }
}
