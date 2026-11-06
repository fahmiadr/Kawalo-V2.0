// CLI tool for generating Kawalo vector icon constants.
// ignore_for_file: avoid_print, avoid_catches_without_on_clauses

import 'dart:convert';
import 'dart:io';

/// Script untuk men-generate class konstan `KawaloVectors` dan
/// `KawaloColorVectors` secara otomatis dari aset ikon Kawalo.
///
/// Cara pakai:
///   dart run tool/generate_vectors.dart
void main() {
  final vectorDir = Directory('assets/icons/vector');
  final colorDir = Directory('assets/icons/color');
  final outputFile = File('lib/core/theme/kawalo_vectors.dart');

  if (!vectorDir.existsSync()) {
    print('❌ Direktori ${vectorDir.path} tidak ditemukan.');
    exit(1);
  }

  // Ekstrak file PNG dari SVG berwarna jika berisi base64 embedded image
  if (colorDir.existsSync()) {
    _extractEmbeddedPngs(colorDir);
  }

  final vectorSvgFiles = _getFiles(vectorDir, '.svg');
  final colorPngFiles = colorDir.existsSync()
      ? _getFiles(colorDir, '.png')
      : <File>[];

  final buffer = StringBuffer()
    ..writeln(
      '/// Kumpulan path konstan untuk seluruh aset vektor SVG '
      'aplikasi Kawalo.',
    )
    ..writeln(
      '/// File ini dibuat otomatis via `tool/generate_vectors.dart`.',
    )
    ..writeln('class KawaloVectors {')
    ..writeln('  const KawaloVectors._();')
    ..writeln()
    ..writeln("  static const String _basePath = 'assets/icons/vector';")
    ..writeln();

  _writeIconConstants(buffer, vectorSvgFiles);

  buffer
    ..writeln('}')
    ..writeln()
    ..writeln(
      '/// Kumpulan path konstan untuk seluruh aset SVG/PNG berwarna '
      '(multi-color)',
    )
    ..writeln('/// aplikasi Kawalo.')
    ..writeln('class KawaloColorVectors {')
    ..writeln('  const KawaloColorVectors._();')
    ..writeln()
    ..writeln("  static const String _basePath = 'assets/icons/color';")
    ..writeln();

  _writeIconConstants(buffer, colorPngFiles);

  buffer.writeln('}');

  outputFile.writeAsStringSync('${buffer.toString().trimRight()}\n');
  print(
    '✅ Berhasil membuat ${vectorSvgFiles.length} konstanta vektor dan '
    '${colorPngFiles.length} konstanta ikon berwarna di ${outputFile.path}',
  );
}

void _extractEmbeddedPngs(Directory dir) {
  final regExp = RegExp('href="data:image/png;base64,([^"]+)"');
  final svgFiles = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.svg'));

  for (final file in svgFiles) {
    try {
      final content = file.readAsStringSync();
      final match = regExp.firstMatch(content);
      if (match != null) {
        final base64Str = match.group(1)!;
        final bytes = base64Decode(base64Str);
        final pngPath = file.path.replaceAll(
          RegExp(r'\.svg$', caseSensitive: false),
          '.png',
        );
        File(pngPath).writeAsBytesSync(bytes);
      }
    } catch (_) {
      // Ignore errors for non-matching or corrupted files
    }
  }
}

List<File> _getFiles(Directory dir, String extension) {
  return dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith(extension))
      .toList()
    ..sort((a, b) {
      final nameA = a.uri.pathSegments.last;
      final nameB = b.uri.pathSegments.last;
      return nameA.compareTo(nameB);
    });
}

void _writeIconConstants(StringBuffer buffer, List<File> files) {
  String? currentGroup;

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    final rawName = fileName.substring(0, fileName.length - 4);
    final varName = _toCamelCase(rawName);

    final firstChar = varName.isNotEmpty ? varName[0].toUpperCase() : '';
    if (firstChar.isNotEmpty && firstChar != currentGroup) {
      currentGroup = firstChar;
      buffer.writeln('  // $currentGroup');
    }

    final singleLine =
        "  static const String $varName = '\$_basePath/$fileName';";
    if (singleLine.length <= 80) {
      buffer.writeln(singleLine);
    } else {
      buffer
        ..writeln('  static const String $varName =')
        ..writeln("      '\$_basePath/$fileName';");
    }
  }
}

/// Mengonversi nama file berkebab-case / snake_case ke camelCase yang valid di Dart.
String _toCamelCase(String text) {
  final cleanText = text.replaceAll(RegExp('[^a-zA-Z0-9_]'), '-');
  final parts = cleanText.split(RegExp('[-_]+')).where((p) => p.isNotEmpty);

  final buffer = StringBuffer();
  var isFirst = true;

  for (final part in parts) {
    if (isFirst) {
      buffer.write(part.toLowerCase());
      isFirst = false;
    } else {
      buffer.write(
        part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase(),
      );
    }
  }

  var result = buffer.toString();
  // Cegah identifier yang diawali angka
  if (result.isNotEmpty && RegExp('^[0-9]').hasMatch(result)) {
    result = 'v$result';
  }
  return result;
}
