/// Normalisasi input teks opsional sebelum dikirim sebagai payload.
extension TrimmedOrNull on String? {
  /// Nilai yang sudah di-trim, atau `null` bila `null` / kosong / hanya spasi.
  String? get trimmedOrNull {
    final trimmed = this?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
