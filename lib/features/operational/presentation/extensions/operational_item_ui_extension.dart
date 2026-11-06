import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';

/// Ekstensi lapisan presentasi untuk [DutyTimelineEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, tag styling,
/// dan waktu terformat) tanpa mencemari lapisan Domain.
extension DutyTimelineUiExtension on DutyTimelineEntity {
  /// Teks tugas terformat yang ramah pengguna (em-dash jika kosong/null).
  String get displayDuty => duty.toDisplay();

  /// Teks status terformat yang ramah pengguna (em-dash jika kosong/null).
  String get displayState => state.toDisplay();

  /// Waktu pelaksanaan tugas terformat yang ramah pengguna.
  String get displayTime => dutyDt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// Menandakan apakah tugas ini berstatus "ON DUTY".
  bool get isOnDuty => displayDuty.toUpperCase().contains('ON');

  /// Menentukan varian [AppTagVariant] untuk tugas linimasa.
  AppTagVariant displayDutyTagVariant({bool isFirst = false}) {
    if (isOnDuty) {
      return isFirst ? AppTagVariant.primary : AppTagVariant.secondary;
    }
    return AppTagVariant.tertiary;
  }

  /// Menentukan varian [AppTagVariant] untuk status tugas linimasa.
  AppTagVariant get displayStateTagVariant =>
      OperationalItemUiExtension.resolveStateTagVariant(state);
}

/// Ekstensi lapisan presentasi untuk [OperationalItemEntity].
///
/// Menyediakan pemformatan UI yang aman (display getters, tag styling,
/// dan string terformat) tanpa mencemari lapisan Domain.
extension OperationalItemUiExtension on OperationalItemEntity {
  /// Nama personil yang aman untuk tampilan UI (em-dash jika kosong/null).
  String get displayUserName => userName.toDisplay();

  /// Email personil yang aman untuk tampilan UI.
  String get displayUserEmail => userEmail.toDisplay();

  /// Nama grup kawasan yang aman untuk tampilan UI.
  String get displayGroupName => groupName.toDisplay();

  /// Teks tugas terakhir yang aman untuk tampilan UI.
  String get displayLatestDuty => latestDuty.toDisplay();

  /// Teks status terakhir yang aman untuk tampilan UI.
  String get displayLatestState => latestState.toDisplay();

  /// Waktu pelaksanaan tugas terakhir yang aman untuk tampilan UI.
  String get displayLatestTime =>
      latestDutyDt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// Waktu status terakhir tugas yang aman untuk tampilan UI.
  String get displayLatestStateTime =>
      latestStateDt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// Waktu pelaksanaan tugas pertama pada hari bersangkutan berdasarkan
  /// linimasa kronologis.
  String? get firstActivityDt {
    if (timeline.isEmpty) return latestDutyDt;
    var earliest = timeline.first;
    DateTime? earliestParsed;
    final firstDutyDt = earliest.dutyDt;
    if (firstDutyDt != null) {
      earliestParsed = DateTime.tryParse(firstDutyDt);
    }

    for (final item in timeline) {
      final itemDutyDt = item.dutyDt;
      if (itemDutyDt == null) continue;
      final parsed = DateTime.tryParse(itemDutyDt);
      if (parsed != null) {
        if (earliestParsed == null || parsed.isBefore(earliestParsed)) {
          earliest = item;
          earliestParsed = parsed;
        }
      }
    }
    return earliest.dutyDt ?? latestDutyDt;
  }

  /// Waktu pelaksanaan aktivitas pertama yang aman untuk tampilan UI.
  String get displayFirstActivityTime =>
      firstActivityDt.toDisplayFormat(AppDateFormat.formatRawDate);

  /// Total aktivitas yang aman untuk tampilan UI.
  String get displayTotalActivities => totalActivities.toString();

  /// Menandakan apakah personil berstatus "ON DUTY".
  bool get isOnDuty => displayLatestDuty.toUpperCase().contains('ON');

  /// Menentukan varian [AppTagVariant] untuk tugas dinas terkini.
  AppTagVariant get displayDutyTagVariant =>
      isOnDuty ? AppTagVariant.primary : AppTagVariant.tertiary;

  /// Menentukan varian [AppTagVariant] untuk kondisi status dinas terkini.
  AppTagVariant get displayStateTagVariant =>
      resolveStateTagVariant(latestState);

  /// Menentukan varian [AppTagVariant] berbasis teks status tugas operasional.
  static AppTagVariant resolveStateTagVariant(String? state) {
    if (state == null || state.trim().isEmpty) {
      return AppTagVariant.secondary;
    }
    final s = state.toLowerCase();
    if (s.contains('aktif') || s.contains('berjalan')) {
      return AppTagVariant.primary;
    } else if (s.contains('selesai')) {
      return AppTagVariant.tertiary;
    } else if (s.contains('standby') || s.contains('siaga')) {
      return AppTagVariant.secondary;
    } else if (s.contains('darurat') || s.contains('bahaya')) {
      return AppTagVariant.error;
    }
    return AppTagVariant.secondary;
  }
}
