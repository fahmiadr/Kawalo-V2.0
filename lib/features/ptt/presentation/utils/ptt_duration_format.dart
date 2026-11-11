/// `m:ss`, e.g. `0:07` or `1:05`, the way voice notes show their length.
String formatPttDuration(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '${totalSeconds ~/ 60}:$seconds';
}
