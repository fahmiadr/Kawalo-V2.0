import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/duration_text.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';

/// `HH:MM` of a stored clock time (`HH:MM:SS`).
String hhmm(String clock) => clock.length >= 5 ? clock.substring(0, 5) : clock;

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// `AttendanceCheckInReady` / `AttendanceCheckOutReady`. The map and the
/// distance of the artboards are left out: `GET /schedules/me` has no shift
/// coordinates, and the server checks the radius on submit.
class AttendanceReadyView extends StatelessWidget {
  const AttendanceReadyView({
    required this.state,
    required this.now,
    required this.onStart,
    required this.onClose,
    super.key,
  });

  final AttendanceCheckReady state;
  final DateTime now;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    final slot = state.slot;
    final checkIn = state.action == AttendanceAction.checkIn;
    final accuracy = state.accuracyMeters;
    final checkin = slot.checkin;

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          semanticLabel: 'Tutup',
          onPressed: onClose,
          icon: const AppSvgIcon(KawaloVectors.cancel01),
        ),
        title: const Text('Absensi'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space200),
                children: [
                  Text(
                    AppDateFormat.formatWeekdayDate(now),
                    style: typeScale.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGap50,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slot.shiftName,
                          style: emphasized.headlineSmall,
                        ),
                      ),
                      AppTag(
                        label: checkIn ? 'Hari ini' : 'Sedang bertugas',
                        variant: checkIn
                            ? AppTagVariant.neutral
                            : AppTagVariant.primary,
                      ),
                    ],
                  ),
                  AppSpacing.vGap200,
                  FaceInfoCard(
                    children: [
                      FaceInfoRow(
                        icon: KawaloVectors.clockHour5,
                        label: 'Jam kerja',
                        value: slot.timeWindow,
                      ),
                      FaceInfoRow(
                        icon: KawaloVectors.location01,
                        label: 'Lokasi absen',
                        value: slot.locationName ?? 'Belum diatur admin',
                      ),
                      if (!checkIn && checkin != null)
                        FaceInfoRow(
                          icon: KawaloVectors.login03,
                          label: 'Check-in hari ini',
                          value:
                              '${hhmm(checkin)} · bertugas '
                              '${_onDuty(slot.date, checkin, now)}',
                        ),
                      FaceInfoRow(
                        icon: KawaloVectors.gps01,
                        label: 'Lokasi Anda',
                        value: accuracy == null
                            ? 'Lokasi didapat'
                            : 'Lokasi didapat · GPS ±${accuracy.round()} m',
                      ),
                      const FaceInfoRow(
                        icon: KawaloVectors.userShield01,
                        label: 'Verifikasi wajah',
                        value: 'Wajah terdaftar · Siap',
                      ),
                    ],
                  ),
                  AppSpacing.vGap150,
                  Text(
                    'Jarak ke lokasi absen diperiksa server saat Anda absen.',
                    style: typeScale.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space200,
                AppSpacing.space150,
                AppSpacing.space200,
                AppSpacing.space300,
              ),
              child: AppButton(
                size: AppButtonSize.md,
                onPressed: onStart,
                child: Text(
                  checkIn ? 'Check-in dengan Wajah' : 'Check-out dengan Wajah',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _onDuty(DateTime day, String clock, DateTime now) {
    final parts = clock.split(':');
    final since = DateTime(
      day.year,
      day.month,
      day.day,
      int.tryParse(parts.first) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final minutes = now.difference(since).inMinutes;
    if (minutes < 0) return '0 menit';
    final hours = minutes ~/ 60;
    return hours == 0
        ? '${minutes % 60} menit'
        : '$hours jam ${minutes % 60} menit';
  }
}

/// Check-in/out outcome. Late check-in and early check-out are red, every
/// other result green (user decision 12 Nov 2026).
class AttendanceResultView extends StatelessWidget {
  const AttendanceResultView({
    required this.result,
    required this.onDone,
    required this.onOpenList,
    super.key,
  });

  final AttendanceCheckResult result;
  final VoidCallback onDone;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    final red = result.isWarning;
    final checkIn = result.isCheckIn;
    final time =
        '${_twoDigits(result.attendanceAt.hour)}:'
        '${_twoDigits(result.attendanceAt.minute)}';
    final String title;
    final String message;
    final String tag;
    if (checkIn) {
      title = red ? 'Check-in tercatat' : 'Check-in berhasil';
      message = red
          ? 'Anda masuk setelah jam shift dimulai.'
          : 'Selamat bertugas.';
      tag = red
          ? 'Terlambat ${formatMinutes(result.lateMinutes)}'
          : 'Tepat waktu';
    } else {
      title = red ? 'Check-out tercatat' : 'Check-out berhasil';
      message = red
          ? 'Anda pulang sebelum jam shift berakhir.'
          : 'Terima kasih, hati-hati di jalan.';
      tag = red
          ? 'Pulang ${formatMinutes(result.earlyLeaveMinutes)} lebih cepat'
          : 'Sesuai jadwal';
    }
    final shift = [
      result.shiftName,
      result.shiftTimeWindow,
    ].whereType<String>().join(' · ');
    final distance = result.distanceMeters;
    final place = [
      result.locationName,
      if (distance != null) '$distance m dari titik',
    ].whereType<String>().join(' · ');

    return FaceResultLayout(
      tone: red ? FaceResultTone.error : FaceResultTone.success,
      icon: red
          ? KawaloVectors.clockHour5
          : KawaloVectors.checkmarkCircle01Filled,
      title: title,
      message: message,
      content: [
        Text(
          '${checkIn ? 'Masuk' : 'Pulang'} $time',
          textAlign: TextAlign.center,
          style: emphasized.displaySmall.copyWith(fontWeight: FontWeight.w800),
        ),
        AppSpacing.vGap100,
        Center(
          child: AppTag(
            label: tag,
            variant: red ? AppTagVariant.error : AppTagVariant.primary,
          ),
        ),
        AppSpacing.vGap200,
        FaceInfoCard(
          children: [
            if (shift.isNotEmpty)
              FaceInfoRow(
                icon: KawaloVectors.clockHour5,
                label: 'Shift',
                value: shift,
              ),
            if (place.isNotEmpty)
              FaceInfoRow(
                icon: KawaloVectors.location01,
                label: 'Lokasi',
                value: place,
              ),
            const FaceInfoRow(
              icon: KawaloVectors.userShield01,
              label: 'Verifikasi',
              value: 'Terverifikasi wajah',
            ),
          ],
        ),
      ],
      actions: [
        FaceResultAction('Selesai', onDone),
        FaceResultAction(
          'Lihat Data Absensi',
          onOpenList,
          style: AppButtonColor.tonal,
        ),
      ],
    );
  }
}

/// `AttendanceFaceNotMatch`: retrying with the face is always the main action
/// at any failure count; the manual report is an extra choice once the server
/// allows it.
class FaceNotMatchView extends StatelessWidget {
  const FaceNotMatchView({
    required this.state,
    required this.onRetry,
    required this.onReport,
    required this.onBack,
    super.key,
  });

  final AttendanceCheckFaceNotMatch state;
  final VoidCallback onRetry;
  final VoidCallback onReport;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final manual = state.canRequestManual;
    return FaceResultLayout(
      tone: FaceResultTone.error,
      icon: KawaloVectors.cancelCircleFilled,
      title: 'Wajah belum cocok',
      message: manual
          ? 'Anda bisa mencoba lagi, atau melapor ke admin untuk absen '
                'manual.'
          : 'Anda bisa mencoba lagi. Pastikan wajah terlihat jelas dan '
                'cahaya cukup.',
      content: [
        FaceInfoCard(
          children: [
            FaceInfoRow(
              icon: KawaloVectors.alertCircle,
              label: 'Percobaan gagal',
              value: '${state.failedAttempts} kali',
            ),
            if (manual)
              const FaceInfoRow(
                icon: KawaloVectors.helpCircle,
                label: 'Masih gagal atau kamera bermasalah?',
                value: 'Laporkan ke admin agar absen Anda dicatat manual.',
              ),
          ],
        ),
      ],
      actions: [
        FaceResultAction('Coba Lagi', onRetry),
        if (manual)
          FaceResultAction(
            'Lapor ke Admin',
            onReport,
            style: AppButtonColor.tonal,
          ),
        FaceResultAction('Kembali', onBack, style: AppButtonColor.tonal),
      ],
    );
  }
}

/// Emergency path: asks the group admin to record the attendance manually.
class ManualRequestView extends StatefulWidget {
  const ManualRequestView({
    required this.state,
    required this.onSend,
    required this.onCancel,
    super.key,
  });

  final AttendanceCheckManualRequest state;
  final ValueChanged<String?> onSend;
  final VoidCallback onCancel;

  @override
  State<ManualRequestView> createState() => _ManualRequestViewState();
}

class _ManualRequestViewState extends State<ManualRequestView> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    final state = widget.state;
    final reason = state.reason == ManualAttendanceReason.faceFailed
        ? 'Wajah tidak dikenali setelah beberapa percobaan.'
        : 'Kamera depan tidak dapat dipakai.';
    final error = state.error;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.sending) widget.onCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: AppIconButton(
            semanticLabel: 'Batal',
            onPressed: state.sending ? null : widget.onCancel,
            icon: const AppSvgIcon(KawaloVectors.cancel01),
          ),
          title: const Text('Lapor ke Admin'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.space200),
                  children: [
                    Text(
                      'Minta absen dicatat manual',
                      style: emphasized.headlineSmall,
                    ),
                    AppSpacing.vGap100,
                    Text(
                      'Admin grup menerima laporan ini beserta lokasi Anda '
                      'saat ini, lalu meninjau dan mencatat absensi Anda. '
                      'Absen belum tercatat sampai admin menyetujuinya.',
                      style: typeScale.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGap200,
                    FaceInfoCard(
                      children: [
                        FaceInfoRow(
                          icon: KawaloVectors.alertCircle,
                          label: 'Alasan',
                          value: reason,
                        ),
                      ],
                    ),
                    AppSpacing.vGap200,
                    TextField(
                      controller: _note,
                      enabled: !state.sending,
                      maxLength: 200,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Mis. kamera retak, cahaya pos sangat gelap',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error != null) ...[
                      AppSpacing.vGap100,
                      Text(
                        error,
                        style: typeScale.bodyMedium.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space200,
                  AppSpacing.space150,
                  AppSpacing.space200,
                  AppSpacing.space300,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      size: AppButtonSize.md,
                      enabled: !state.sending,
                      onPressed: () => widget.onSend(_note.text),
                      child: Text(
                        state.sending ? 'Mengirim...' : 'Kirim Laporan',
                      ),
                    ),
                    AppSpacing.vGap100,
                    AppButton(
                      style: AppButtonColor.tonal,
                      size: AppButtonSize.md,
                      enabled: !state.sending,
                      onPressed: widget.onCancel,
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
