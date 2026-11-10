/// Extracts the guest `qr_uid` from the raw text of a scanned QR code.
///
/// The API defines no wrapper format: `qr_uid` is a server-generated UUID that
/// the endpoints take verbatim and validate as `^[a-zA-Z0-9_-]{1,64}$`, so the
/// QR is assumed to carry exactly that token.
abstract final class GuestQrPayload {
  static final RegExp _token = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  /// Returns the `qr_uid`, or `null` when [raw] cannot be one.
  ///
  /// Digits-only payloads are rejected on purpose: `GET /guests/:id` also
  /// matches a numeric value against the row id, so an unrelated numeric
  /// barcode would open an arbitrary guest of the group.
  static String? tryParse(String? raw) {
    final value = raw?.trim();
    if (value == null || !_token.hasMatch(value)) return null;
    if (_digitsOnly.hasMatch(value)) return null;
    return value;
  }
}
