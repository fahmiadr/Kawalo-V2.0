import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/duration_text.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// `HH:MM` of a stored clock time (`HH:MM:SS`).
String hhmm(String clock) => clock.length >= 5 ? clock.substring(0, 5) : clock;

/// Indonesian clock notation, `07.12`.
String dotTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

/// Minutes a check-out at [now] leaves before the shift end, or null when it
/// is not an early check-out (`RdBerandaLainnyaPulangAwal` asks first).
int? earlyCheckoutMinutes(
  AttendanceSlot slot,
  AttendanceAction action,
  DateTime now,
) {
  if (action != AttendanceAction.checkOut || !now.isBefore(slot.endsAt)) {
    return null;
  }
  final minutes = slot.endsAt.difference(now).inMinutes;
  return minutes < 1 ? 1 : minutes;
}

/// Check-in/out outcome (`RdAbsenBerhasil`, `RdAbsenTerlambat`,
/// `RdAbsenPulang`): the recorded time large, a late check-in or an early
/// check-out flagged with an amber pill.
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
    final warn = result.isWarning;
    final checkIn = result.isCheckIn;
    final String tag;
    if (checkIn) {
      tag = warn
          ? 'Terlambat ${formatMinutes(result.lateMinutes)}'
          : 'Tepat waktu';
    } else {
      tag = warn
          ? 'Pulang ${formatMinutes(result.earlyLeaveMinutes)} lebih cepat'
          : 'Sesuai jadwal';
    }
    final distance = result.distanceMeters;
    final note = [
      result.shiftName,
      result.locationName,
      if (distance != null) '$distance m dari titik',
      'Terverifikasi wajah',
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return FaceResultLayout(
      tone: FaceResultTone.success,
      icon: KawaloVectors.check,
      title: checkIn ? 'Check-in berhasil' : 'Check-out berhasil',
      message: note,
      highlights: [
        Semantics(
          label:
              '${checkIn ? 'Masuk' : 'Pulang'} pukul '
              '${dotTime(result.attendanceAt)}',
          excludeSemantics: true,
          child: TaskBigTime(dotTime(result.attendanceAt)),
        ),
        AppStatusPill(
          label: tag,
          kind: warn ? AppStatusKind.bad : AppStatusKind.ok,
        ),
      ],
      actions: [
        FaceResultAction('Kembali ke Beranda', onDone),
        FaceResultAction(
          'Lihat Riwayat Absen',
          onOpenList,
          style: AppButtonColor.tonal,
        ),
      ],
    );
  }
}

/// Face mismatch. Retrying is offered at any failure count; once the server
/// allows a manual report (`RdAbsenGagal3x`) that report becomes the primary
/// action and "Coba Lagi" stays as the second.
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
      icon: KawaloVectors.cancel01,
      title: manual ? 'Wajah tidak dikenali' : 'Wajah belum cocok',
      message: manual
          ? 'Sudah ${state.failedAttempts} kali gagal. Minta admin mencatat '
                'absen Anda secara manual, atau coba lagi.'
          : 'Pastikan wajah terlihat jelas dan cahaya cukup, lalu coba lagi.',
      onClose: onBack,
      actions: manual
          ? [
              FaceResultAction('Lapor ke Admin', onReport),
              FaceResultAction(
                'Coba Lagi',
                onRetry,
                style: AppButtonColor.tonal,
              ),
            ]
          : [
              FaceResultAction('Coba Lagi', onRetry),
              FaceResultAction('Kembali', onBack, style: AppButtonColor.tonal),
            ],
    );
  }
}

/// `RdLaporAdmin`: asks the group admin to record the attendance manually.
/// The reason is fixed by the flow; the note is the only (optional) field.
class ManualRequestView extends StatefulWidget {
  const ManualRequestView({
    required this.state,
    required this.onSend,
    required this.onCancel,
    super.key,
    this.subtitle,
  });

  final AttendanceCheckManualRequest state;
  final ValueChanged<String?> onSend;
  final VoidCallback onCancel;

  /// e.g. "Check-in Shift Pagi".
  final String? subtitle;

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
    final tones = KawaloTones.of(context);
    final state = widget.state;
    final reason = state.reason == ManualAttendanceReason.faceFailed
        ? 'Wajah tidak dikenali setelah beberapa percobaan'
        : 'Kamera depan tidak dapat dipakai';
    final error = state.error;
    final label = TextStyle(
      color: tones.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: 1.5),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.sending) widget.onCancel();
      },
      child: TaskScaffold(
        title: 'Lapor ke Admin',
        subtitle: widget.subtitle,
        closeIcon: true,
        onClose: state.sending ? () {} : widget.onCancel,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tones.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: tones.ink2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Absen belum tercatat sampai admin menyetujui laporan '
                      'ini.',
                      style: TextStyle(
                        color: tones.ink2,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Alasan', style: label),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tones.surface2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 20, color: tones.ink2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(color: tones.ink, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'Catatan ',
                children: [
                  TextSpan(
                    text: '(opsional)',
                    style: TextStyle(
                      color: tones.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              style: label,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _note,
              enabled: !state.sending,
              maxLength: 200,
              maxLines: 3,
              style: TextStyle(color: tones.ink, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Contoh: kamera retak, pos sangat gelap',
                filled: true,
                fillColor: tones.surface,
                enabledBorder: border(tones.line),
                focusedBorder: border(tones.abs.color),
                disabledBorder: border(tones.line),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(color: tones.line, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: tones.ink2,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lokasi Anda ikut terkirim',
                      style: TextStyle(
                        color: tones.ink2,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(
                  color: tones.sos.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        footer: [
          taskPrimary(
            state.sending ? 'Mengirim…' : 'Kirim Laporan',
            () => widget.onSend(_note.text),
            tone: tones.abs,
            icon: Icons.send_rounded,
            isLoading: state.sending,
          ),
        ],
      ),
    );
  }
}

/// `RdLaporAdminTerkirim`.
class ManualSentView extends StatelessWidget {
  const ManualSentView({
    required this.alreadyPending,
    required this.onDone,
    super.key,
  });

  final bool alreadyPending;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return FaceResultLayout(
      tone: FaceResultTone.success,
      icon: KawaloVectors.check,
      title: alreadyPending ? 'Laporan sudah ada' : 'Laporan terkirim',
      message: alreadyPending
          ? 'Laporan Anda sebelumnya masih menunggu tinjauan admin grup.'
          : 'Absen tercatat setelah admin grup menyetujui laporan ini.',
      highlights: const [
        AppStatusPill(label: 'Menunggu admin', kind: AppStatusKind.warn),
      ],
      actions: [FaceResultAction('Kembali ke Beranda', onDone)],
    );
  }
}
