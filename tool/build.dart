// CLI tool for orchestrating Kawalo Mobile builds with Quality Gates.
// ignore_for_file: avoid_print

import 'dart:io';

/// Platform target kompilasi yang didukung.
enum BuildPlatform {
  android,
  ios;

  static BuildPlatform? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'android':
        return BuildPlatform.android;
      case 'ios':
        return BuildPlatform.ios;
      default:
        return null;
    }
  }
}

/// Target environment entry point.
enum BuildTarget {
  prod('lib/main_prod.dart'),
  staging('lib/main_staging.dart'),
  dev('lib/main_dev.dart');

  const BuildTarget(this.entryPoint);
  final String entryPoint;

  static BuildTarget? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'prod':
      case 'production':
        return BuildTarget.prod;
      case 'staging':
      case 'stg':
        return BuildTarget.staging;
      case 'dev':
      case 'development':
        return BuildTarget.dev;
      default:
        return null;
    }
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    _printUsage();
    return;
  }

  // Deteksi otomatis platform default berdasarkan OS host saat ini
  final defaultPlatform = Platform.isMacOS ? 'ios' : 'android';
  final platformArg = _getArg(args, '--platform') ?? defaultPlatform;
  final targetArg = _getArg(args, '--target') ?? 'prod';
  final typeArg = _getArg(args, '--type');
  final skipGates = args.contains('--skip-gates');

  final platform = BuildPlatform.fromString(platformArg);
  if (platform == null) {
    _printError(
      'Platform tidak valid: "$platformArg". Gunakan "android" atau "ios".',
    );
    exit(1);
  }

  if (platform == BuildPlatform.ios && !Platform.isMacOS) {
    _printError(
      'Platform iOS hanya dapat dikompilasi pada mesin macOS dengan Xcode.',
    );
    exit(1);
  }

  final target = BuildTarget.fromString(targetArg);
  if (target == null) {
    _printError(
      'Target tidak valid: "$targetArg". '
      'Gunakan "prod", "staging", atau "dev".',
    );
    exit(1);
  }

  final defaultType = platform == BuildPlatform.android ? 'appbundle' : 'ipa';
  final buildType = typeArg ?? defaultType;

  final stopwatch = Stopwatch()..start();

  _printBanner(
    platform: platform,
    target: target,
    buildType: buildType,
    skipGates: skipGates,
  );

  // --- QUALITY GATES ---
  if (!skipGates) {
    print('📦 [1/3] Quality Gate: Sinkronisasi Dependensi (pub get)...');
    await _runCommand('flutter', ['pub', 'get'], 'Dependency Sync');

    print('\n🔍 [2/3] Quality Gate: Static Analysis (flutter analyze)...');
    await _runCommand('flutter', ['analyze'], 'Static Analysis');

    print('\n🧪 [3/3] Quality Gate: Automated Test Suite (flutter test)...');
    await _runCommand('flutter', ['test'], 'Automated Tests');

    print('\n✅ Seluruh Quality Gates berhasil dilewati dengan sempurna!\n');
  } else {
    print('\n⚠️ Quality Gates dilewati (--skip-gates aktif).\n');
  }

  // --- RELEASE BUILD PIPELINE ---
  final symbolsDir = './build/symbols/${platform.name}';
  final buildArgs = <String>[
    'build',
    buildType,
    '--release',
    '-t',
    target.entryPoint,
    '--dart-define-from-file=.env.${target.name}',
    '--obfuscate',
    '--split-debug-info=$symbolsDir',
  ];

  print('🏗️  [BUILD] Mengompilasi $buildType ($platform, ${target.name})...');
  print('Command: flutter ${buildArgs.join(' ')}\n');

  await _runCommand('flutter', buildArgs, 'Flutter Build $buildType');

  stopwatch.stop();
  final elapsed = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

  _printSuccess(
    platform: platform,
    buildType: buildType,
    symbolsDir: symbolsDir,
    elapsedSeconds: elapsed,
  );
}

Future<void> _runCommand(
  String executable,
  List<String> arguments,
  String stepName,
) async {
  final process = await Process.start(
    executable,
    arguments,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    _printError('Gagal pada tahap "$stepName" (Exit code: $exitCode).');
    _printError('Proses build dibatalkan untuk mencegah rilis cacat.');
    exit(exitCode);
  }
}

String? _getArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith('$prefix=')) {
      return arg.substring(prefix.length + 1).trim();
    }
  }
  final index = args.indexOf(prefix);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1].trim();
  }
  return null;
}

void _printBanner({
  required BuildPlatform platform,
  required BuildTarget target,
  required String buildType,
  required bool skipGates,
}) {
  print('========================================================');
  print('🛡️  KAWALO MOBILE - UNIFIED BUILD ORCHESTRATOR');
  print('Platform      : ${platform.name.toUpperCase()}');
  print('Target Flavor : ${target.name.toUpperCase()} (${target.entryPoint})');
  print('Output Type   : $buildType');
  final gatesStatus = skipGates ? 'DILEWATI (BYPASS)' : 'AKTIF (STRICT)';
  print('Quality Gates : $gatesStatus');
  print('Obfuscation   : AKTIF (--obfuscate --split-debug-info)');
  print('========================================================\n');
}

void _printSuccess({
  required BuildPlatform platform,
  required String buildType,
  required String symbolsDir,
  required String elapsedSeconds,
}) {
  print('\n========================================================');
  print('🎉 [SUCCESS] Build Release Berhasil Dibuat! (${elapsedSeconds}s)');
  if (platform == BuildPlatform.android) {
    if (buildType == 'appbundle') {
      print('Output AAB   : build/app/outputs/bundle/release/app-release.aab');
    } else {
      print('Output APK   : build/app/outputs/flutter-apk/app-release.apk');
    }
  } else {
    print('Output IPA   : build/ios/ipa');
  }
  print('Debug Symbols: $symbolsDir');
  print('========================================================\n');
}

void _printError(String message) {
  print('\n❌ [ERROR] $message');
}

void _printUsage() {
  print('''
Kawalo Mobile - Unified Build Orchestrator CLI

Satu-satunya entry point untuk build aplikasi Kawalo Mobile secara cross-platform
dengan Quality Gates otomatis (pub get, flutter analyze, flutter test).

Penggunaan:
  dart run tool/build.dart [opsi]

Opsi:
  --platform=<android|ios>    Target OS (default otomatis: Android di Windows/Linux, iOS di macOS)
  --target=<prod|staging|dev> Target environment entry point (default: prod)
  --type=<appbundle|apk|ipa>  Format output binary (default: appbundle/ipa)
  --skip-gates                Lewati Quality Gates jika butuh kompilasi cepat
  -h, --help                  Menampilkan bantuan ini

Contoh:
  # Cukup satu perintah untuk build rilis production:
  dart run tool/build.dart

  # Build target spesifik:
  dart run tool/build.dart --platform=android
  dart run tool/build.dart --platform=android --type=apk
  dart run tool/build.dart --platform=ios
  dart run tool/build.dart --target=staging
''');
}
