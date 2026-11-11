import 'package:equatable/equatable.dart';

/// Outcome of the on-device transcription of one of the user's own turns.
/// `failed` and `unsupported` carry no text; they tell the server worker to
/// transcribe the turn itself instead of waiting for its grace period.
enum PttTranscriptStatus {
  ok,
  unsupported,
  failed;

  static PttTranscriptStatus? tryParse(String? wire) {
    for (final status in values) {
      if (status.name == wire) return status;
    }
    return null;
  }
}

class PttTranscript extends Equatable {
  const PttTranscript({
    required this.requestId,
    required this.status,
    this.text,
    this.locale,
    this.reason,
  });

  /// The `requestId` of the turn's FLOOR_REQUEST; the server stores the
  /// recording under it.
  final String requestId;
  final PttTranscriptStatus status;
  final String? text;
  final String? locale;

  /// Why the native side reported this status. Diagnostics only: logged,
  /// never stored, uploaded or shown.
  final String? reason;

  @override
  List<Object?> get props => [requestId, status, text, locale, reason];
}
