import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';

/// Ekstensi lapisan presentasi untuk [IncidentEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, format tanggal,
/// status tag variant, dan fallback string) tanpa mencemari lapisan Domain.
extension IncidentUiExtension on IncidentEntity {
  /// Judul insiden yang aman untuk tampilan UI.
  String get displayTitle => title.isNotEmpty ? title : '-';

  /// Nama pembuat/pelapor laporan insiden.
  String get displayReporter =>
      (createdByName != null && createdByName!.isNotEmpty)
      ? createdByName!
      : 'Petugas';

  /// Nama resolver/penyelesai insiden.
  String get displayResolver =>
      (resolvedByName != null && resolvedByName!.isNotEmpty)
      ? resolvedByName!
      : 'Petugas';

  /// Label status untuk tampilan UI.
  String get displayStatusLabel => isOpen ? 'Terbuka' : 'Selesai';

  /// Waktu relatif ramah pembaca untuk kartu ringkasan (misal "5 mnt lalu").
  String get displayRelativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return AppDateFormat.formatDate(createdAt);
    }
  }
}
