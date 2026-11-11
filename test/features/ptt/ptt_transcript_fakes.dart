import 'dart:math';

import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_local_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_transcript_local_model.dart';

/// In-memory stand-in for the Isar outbox with the same contract (replace by
/// requestId, cap by age, update only while present).
class FakeTranscriptLocalDataSource implements PttTranscriptLocalDataSource {
  final entries = <String, PttTranscriptLocalModel>{};

  @override
  String get collectionName => 'PttTranscriptLocalModel';

  @override
  Future<void> put(
    PttTranscriptLocalModel entry, {
    required int maxEntries,
  }) async {
    entries[entry.requestId] = entry;
    final sorted = await getAll();
    for (final old in sorted.take(max(0, sorted.length - maxEntries))) {
      entries.remove(old.requestId);
    }
  }

  @override
  Future<List<PttTranscriptLocalModel>> getAll() async =>
      entries.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> updateIfPresent(PttTranscriptLocalModel entry) async {
    if (entries.containsKey(entry.requestId)) {
      entries[entry.requestId] = entry;
    }
  }

  @override
  Future<void> delete(String requestId) async => entries.remove(requestId);

  @override
  Future<void> clearCache() async => entries.clear();
}
