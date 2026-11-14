import 'dart:convert';
import 'dart:typed_data';

import 'package:kawalo_mobile/features/ptt/data/models/ptt_recording_model.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/value_objects/ptt_recording_page.dart';

abstract final class PttRecordingMapper {
  const PttRecordingMapper._();

  static PttRecordingEntity toEntity(PttRecordingModel model) {
    return PttRecordingEntity(
      id: model.id,
      speakerId: model.speaker.id,
      speakerName: model.speaker.name,
      speakerRole: model.speaker.role,
      speakerEmail: model.speaker.email,
      speakerAvatarUrl: model.speaker.avatarUrl,
      startedAt: (DateTime.tryParse(model.startedAt) ?? DateTime.now())
          .toLocal(),
      duration: Duration(milliseconds: model.durationMs),
      sizeBytes: model.sizeBytes,
      transcript: model.transcript,
      transcriptLocale: model.transcriptLocale,
      transcriptSource: PttTranscriptSource.tryParse(model.transcriptSource),
      transcriptStatus: model.transcriptStatus,
      waveform: _waveform(model.waveform),
    );
  }

  /// A malformed value is dropped rather than failing the whole page; the
  /// bubble then draws its neutral fallback.
  static Uint8List? _waveform(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64.decode(raw);
    } on FormatException {
      return null;
    }
  }

  static PttRecordingPage toPage(PttRecordingPageModel model) {
    return PttRecordingPage(
      items: model.items.map(toEntity).toList(),
      nextBefore: model.nextBefore,
    );
  }
}
