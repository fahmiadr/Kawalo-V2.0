import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';

/// Ekstensi lapisan presentasi untuk [IncidentEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, format tanggal,
/// status tag variant, dan fallback string) tanpa mencemari lapisan Domain.
extension IncidentUiExtension on IncidentEntity {
  /// Judul insiden yang aman untuk tampilan UI.
  String get displayTitle => title.isNotEmpty ? title : '-';

  /// Nama kategori insiden untuk tampilan UI.
  String get displayCategory =>
      category?.displayName ?? IncidentCategory.general.displayName;

  /// Penjelasan atau deskripsi insiden yang aman untuk tampilan UI.
  String get displayDescription =>
      (description != null && description!.trim().isNotEmpty)
          ? description!.trim()
          : '-';

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

  /// Format tanggal pembuatan laporan insiden (dd MMM yyyy, HH:mm).
  String get displayCreatedAt => AppDateFormat.formatDate(createdAt);

  /// Format tanggal penyelesaian insiden.
  String get displayResolvedAt =>
      resolvedAt != null ? AppDateFormat.formatDate(resolvedAt!) : '-';

  /// Label status untuk tampilan UI.
  String get displayStatusLabel => isOpen ? 'Terbuka' : 'Selesai';

  /// Varian warna [AppTagVariant] yang sesuai untuk status insiden.
  AppTagVariant get statusVariant =>
      isOpen ? AppTagVariant.error : AppTagVariant.primary;

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
