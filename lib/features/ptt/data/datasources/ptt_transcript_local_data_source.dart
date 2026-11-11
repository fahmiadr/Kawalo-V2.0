import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_transcript_local_model.dart';

abstract interface class PttTranscriptLocalDataSource implements CacheWipeable {
  /// Inserts or replaces the entry with the same `requestId`, then drops the
  /// oldest entries beyond [maxEntries].
  Future<void> put(PttTranscriptLocalModel entry, {required int maxEntries});

  /// Oldest first.
  Future<List<PttTranscriptLocalModel>> getAll();

  /// Saves retry bookkeeping only while the entry still exists, so a logout
  /// wipe that raced an upload is not undone.
  Future<void> updateIfPresent(PttTranscriptLocalModel entry);

  Future<void> delete(String requestId);
}

class PttTranscriptLocalDataSourceImpl implements PttTranscriptLocalDataSource {
  PttTranscriptLocalDataSourceImpl({required this.isar});

  final Isar isar;

  IsarCollection<PttTranscriptLocalModel> get _entries =>
      isar.pttTranscriptLocalModels;

  @override
  String get collectionName => PttTranscriptLocalModelSchema.name;

  @override
  Future<void> put(
    PttTranscriptLocalModel entry, {
    required int maxEntries,
  }) async {
    await isar.writeTxn(() async {
      await _entries.put(entry);
      final overflow = await _entries.count() - maxEntries;
      if (overflow > 0) {
        final oldest = await _entries
            .where()
            .anyCreatedAt()
            .limit(overflow)
            .isarIdProperty()
            .findAll();
        await _entries.deleteAll(oldest);
      }
    });
  }

  @override
  Future<List<PttTranscriptLocalModel>> getAll() =>
      _entries.where().anyCreatedAt().findAll();

  @override
  Future<void> updateIfPresent(PttTranscriptLocalModel entry) async {
    await isar.writeTxn(() async {
      final current = await _entries.getByRequestId(entry.requestId);
      if (current == null) return;
      entry.isarId = current.isarId;
      await _entries.put(entry);
    });
  }

  @override
  Future<void> delete(String requestId) async {
    await isar.writeTxn(() => _entries.deleteByRequestId(requestId));
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(_entries.clear);
  }
}
