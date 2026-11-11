import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_local_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_transcript_local_model.dart';

/// The Isar core ships with `isar_community_flutter_libs`; only its macOS
/// build can be loaded by the host test VM. Elsewhere these tests skip.
String? _isarLibrary() {
  if (!Platform.isMacOS) return null;
  try {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final package = (config['packages'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['name'] == 'isar_community_flutter_libs');
    final root = configFile.uri.resolve('${package['rootUri']}/');
    final lib = File.fromUri(root.resolve('macos/libisar.dylib'));
    return lib.existsSync() ? lib.path : null;
  } on Object {
    return null;
  }
}

PttTranscriptLocalModel entry(String id, DateTime createdAt) =>
    PttTranscriptLocalModel()
      ..requestId = id
      ..status = 'failed'
      ..createdAt = createdAt
      ..nextAttemptAt = createdAt
      ..state = 'pending';

void main() {
  final library = _isarLibrary();
  late Directory dir;
  late Isar isar;
  late PttTranscriptLocalDataSourceImpl local;
  final t0 = DateTime(2026, 11, 11, 10);

  setUpAll(() async {
    if (library == null) return;
    await Isar.initializeIsarCore(
      libraries: {Abi.macosArm64: library, Abi.macosX64: library},
    );
  });

  setUp(() async {
    if (library == null) return;
    dir = Directory.systemTemp.createTempSync('ptt_transcript_isar');
    isar = await Isar.open(
      [PttTranscriptLocalModelSchema],
      directory: dir.path,
      name: 'ptt_transcript_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = PttTranscriptLocalDataSourceImpl(isar: isar);
  });

  tearDown(() async {
    if (library == null) return;
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final skip = library == null ? 'Isar core library not available' : null;

  test('persists entries oldest first and replaces by requestId', () async {
    await local.put(
      entry('b', t0.add(const Duration(seconds: 2))),
      maxEntries: 50,
    );
    await local.put(entry('a', t0), maxEntries: 50);
    await local.put(
      entry('b', t0.add(const Duration(seconds: 2)))..status = 'ok',
      maxEntries: 50,
    );

    final all = await local.getAll();
    expect(all.map((e) => e.requestId), ['a', 'b']);
    expect(all.last.status, 'ok');
  }, skip: skip);

  test('drops the oldest entries beyond the cap', () async {
    for (var i = 0; i < 5; i++) {
      await local.put(
        entry('r$i', t0.add(Duration(seconds: i))),
        maxEntries: 3,
      );
    }

    expect((await local.getAll()).map((e) => e.requestId), ['r2', 'r3', 'r4']);
  }, skip: skip);

  test('updateIfPresent and delete', () async {
    await local.put(entry('a', t0), maxEntries: 50);
    final stored = (await local.getAll()).single
      ..attempts = 3
      ..state = 'parked';
    await local.updateIfPresent(stored);
    expect((await local.getAll()).single.attempts, 3);

    await local.delete('a');
    await local.updateIfPresent(stored);
    expect(await local.getAll(), isEmpty);
  }, skip: skip);

  test('the logout wipe clears the outbox', () async {
    await local.put(entry('a', t0), maxEntries: 50);

    await CacheWiper(wipeables: [local]).wipeAll();

    expect(await local.getAll(), isEmpty);
    expect(local.collectionName, PttTranscriptLocalModelSchema.name);
  }, skip: skip);
}
