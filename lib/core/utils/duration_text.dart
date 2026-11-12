/// Human-readable span for a whole number of minutes: "45 menit", "2 jam",
/// "14 jam 5 menit". Negative values read as their absolute value.
String formatMinutes(int minutes) {
  final total = minutes.abs();
  final hours = total ~/ 60;
  final rest = total % 60;
  if (hours == 0) return '$total menit';
  if (rest == 0) return '$hours jam';
  return '$hours jam $rest menit';
}
