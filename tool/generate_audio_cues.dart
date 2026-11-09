import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// Perkakas CLI ini menggunakan print untuk menampilkan ringkasan keluaran ke
// terminal.
// ignore_for_file: avoid_print

void generateWav(
  String path,
  int durationMs,
  double freqStart,
  double freqEnd,
) {
  const sampleRate = 16000;
  final numSamples = (sampleRate * durationMs / 1000).round();
  final subchunk2Size = numSamples * 2;
  final chunkSize = 36 + subchunk2Size;

  final buffer = ByteData(44 + subchunk2Size);
  var offset = 0;

  void writeString(String s) {
    for (var i = 0; i < s.length; i++) {
      buffer.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  writeString('RIFF');
  buffer.setUint32(offset, chunkSize, Endian.little);
  offset += 4;
  writeString('WAVE');

  writeString('fmt ');
  buffer.setUint32(offset, 16, Endian.little); // Subchunk1Size
  offset += 4;
  buffer.setUint16(offset, 1, Endian.little); // AudioFormat PCM
  offset += 2;
  buffer.setUint16(offset, 1, Endian.little); // NumChannels Mono
  offset += 2;
  buffer.setUint32(offset, sampleRate, Endian.little);
  offset += 4;
  buffer.setUint32(offset, sampleRate * 2, Endian.little); // ByteRate
  offset += 4;
  buffer.setUint16(offset, 2, Endian.little); // BlockAlign
  offset += 2;
  buffer.setUint16(offset, 16, Endian.little); // BitsPerSample
  offset += 2;

  writeString('data');
  buffer.setUint32(offset, subchunk2Size, Endian.little);
  offset += 4;

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final freq = freqStart + (freqEnd - freqStart) * progress;
    final sample = (sin(2 * pi * freq * t) * 16000).round().clamp(
      -32768,
      32767,
    );
    buffer.setInt16(offset, sample, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(buffer.buffer.asUint8List());
}

void main() {
  const dir = 'android/app/src/main/res/raw';
  Directory(dir).createSync(recursive: true);

  // Ascending chirp (floor granted): 1200Hz -> 2400Hz (70ms)
  generateWav('$dir/chirp.wav', 70, 1200, 2400);

  // Low error bonk (floor denied): 280Hz -> 180Hz (90ms)
  generateWav('$dir/bonk.wav', 90, 280, 180);

  // Alert warble (preemption): 1800Hz -> 900Hz (110ms)
  generateWav('$dir/warble.wav', 110, 1800, 900);

  // Roger courtesy beep (floor released): 900Hz (60ms)
  generateWav('$dir/roger.wav', 60, 900, 900);

  print('Generated real WAV audio cues in $dir');
}
