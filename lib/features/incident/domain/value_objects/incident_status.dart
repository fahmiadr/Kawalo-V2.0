/// Enum yang merepresentasikan status siklus hidup sebuah insiden.
enum IncidentStatus {
  /// Insiden baru dilaporkan dan diskusi koordinasi sedang aktif.
  open('OPEN'),

  /// Insiden telah ditangani/diselesaikan dan diskusi thread dikunci (read-only).
  resolved('RESOLVED');

  const IncidentStatus(this.value);

  /// Nilai representasi string wire API.
  final String value;

  /// Memetakan string API ke [IncidentStatus], defaulting ke [open].
  static IncidentStatus fromString(String? raw) {
    if (raw == null) return IncidentStatus.open;
    final upper = raw.trim().toUpperCase();
    if (upper == 'RESOLVED') return IncidentStatus.resolved;
    return IncidentStatus.open;
  }
}
