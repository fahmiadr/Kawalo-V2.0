/// Kontrak agnostik murni untuk token pembatalan operasi asynchronous.
///
/// Berada di Shared Kernel tanpa ketergantungan pada library pihak ketiga
/// (seperti `dio`), sehingga aman diimpor oleh Domain Layer.
abstract class AppCancellationToken {
  /// Status apakah pembatalan telah dipicu.
  bool get isCancelled;

  /// Alasan pembatalan operasi (jika ada).
  String? get cancelReason;

  /// Membatalkan operasi dengan alasan opsional [reason].
  void cancel([String? reason]);
}
