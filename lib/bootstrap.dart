import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/security/device_integrity_service.dart';
import 'package:kawalo_mobile/core/storage/isar_database.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_local_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_local_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_local_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_local_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_local_model.dart';
import 'package:kawalo_mobile/features/ptt/data/models/ptt_transcript_local_model.dart';
import 'package:kawalo_mobile/main.dart';

/// Isar collections opened at startup. Each one needs a matching
/// `CacheWipeableModule` in `main.dart`; `isar_schemas_wipeable_test.dart`
/// fails when one is missing.
final List<CollectionSchema<dynamic>> isarSchemas = [
  AttendanceLocalModelSchema,
  OperationalLocalModelSchema,
  InformationLocalModelSchema,
  GuestLocalModelSchema,
  IncidentLocalModelSchema,
  PttTranscriptLocalModelSchema,
];

/// Runner sentral untuk bootstrapping aplikasi Kawalo Mobile lintas
/// environment.
///
/// Menginisialisasi:
/// 1. Orientasi layar portrait terpadu
///    ([AppLayout.applyPreferredOrientations]).
/// 2. Konfigurasi environment dan guardrails keamanan ([EnvConfig.init]).
/// 3. Validasi integritas perangkat terhadap root/jailbreak & tampering
///    ([DeviceIntegrityService.checkIntegrity]).
/// 4. Engine penyimpanan lokal [IsarDatabase.init].
/// 5. Root widget aplikasi [MyApp].
Future<void> bootstrap(AppEnvironment env) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLayout.applyPreferredOrientations();
  await EnvConfig.init(env);

  final violation = await DeviceIntegrityService.checkIntegrity();
  if (violation != null) {
    runApp(MyApp(securityViolation: violation));
    return;
  }

  final isar = await IsarDatabase.init(schemas: isarSchemas);
  runApp(MyApp(isar: isar));
}
