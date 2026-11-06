import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';

/// Ekstensi lapisan presentasi untuk [InformationItemEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, tag styling,
/// koordinat, dan string terformat) tanpa mencemari lapisan Domain.
extension InformationItemUiExtension on InformationItemEntity {
  /// Judul informasi yang aman untuk tampilan UI.
  String get displayTitle => title.toDisplay();

  /// Narasi teks informasi yang aman untuk tampilan UI.
  String get displayText => text.toDisplay();

  /// Email personil yang aman untuk tampilan UI.
  String get displayUserEmail => userEmail.toDisplay();

  /// Nama personil yang aman untuk tampilan UI.
  String get displayUserName => userName.toDisplay();

  /// Waktu pembuatan feed yang aman dan terformat rapi untuk tampilan UI.
  String get displayFeedDt =>
      feedDt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// Nama lokasi acara atau tempat kejadian yang aman untuk tampilan UI.
  String get displayEventLocation => eventLocation.toDisplay();

  /// Nama grup kawasan yang aman untuk tampilan UI.
  String get displayGroupName => groupName.toDisplay();

  /// Nama berkas lampiran yang aman untuk tampilan UI.
  String get displayFeedFile => feedFile.toDisplay();

  /// Menandakan apakah memiliki berkas lampiran yang valid.
  bool get hasFileAttachment =>
      feedFile != null &&
      feedFile!.trim().isNotEmpty &&
      feedFile != 'N/A' &&
      feedFile != '-' &&
      feedFile != 'null';

  /// Foto utama pertama yang akan ditampilkan pada thumbnail kartu.
  String? get primaryPhoto => photos.isNotEmpty ? photos.first : null;

  /// Menandakan apakah memiliki setidaknya satu foto valid.
  bool get hasPhotos => photos.isNotEmpty;

  /// Jumlah foto tambahan di luar foto utama untuk badge `+N`.
  int get extraPhotosCount => photos.length > 1 ? photos.length - 1 : 0;

  /// Label kategori berbahasa Indonesia yang ramah pengguna.
  String get typeLabel =>
      InformationFeedType.tryFromCode(feedType)?.label ?? 'Informasi Umum';

  /// Varian warna [AppTag] berdasarkan jenis feed.
  AppTagVariant get typeVariant {
    final type = InformationFeedType.tryFromCode(feedType);
    switch (type) {
      case InformationFeedType.incident:
        return AppTagVariant.error;
      case InformationFeedType.event:
        return AppTagVariant.primary;
      case InformationFeedType.join:
        return AppTagVariant.tertiary;
      case InformationFeedType.general:
      case InformationFeedType.other:
      case null:
        return AppTagVariant.secondary;
    }
  }

  /// Label rentang jadwal acara terformat jika tersedia.
  String? get displayEventSchedule {
    final startDt = eventStartDt;
    if (startDt.isNullOrBlank) return null;
    final start = AppDateFormat.tryParse(startDt);
    final endDt = eventEndDt;
    final end = !endDt.isNullOrBlank ? AppDateFormat.tryParse(endDt) : null;

    if (start != null && end != null) {
      final endHour = end.hour.toString().padLeft(2, '0');
      final endMinute = end.minute.toString().padLeft(2, '0');
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return '${AppDateFormat.formatDate(start)} – $endHour:$endMinute';
      }
      return '${AppDateFormat.formatDate(start)} – '
          '${AppDateFormat.formatDate(end)}';
    } else if (start != null) {
      return AppDateFormat.formatDate(start);
    }
    return startDt;
  }
}
