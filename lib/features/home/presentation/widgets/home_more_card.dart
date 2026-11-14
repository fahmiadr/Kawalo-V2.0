import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_feature_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_card_header.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_module.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_screen.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/face/face_module.dart';
import 'package:kawalo_mobile/features/group/presentation/screens/personnel_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_attendance_cubit.dart';
import 'package:kawalo_mobile/features/home/presentation/screens/manage_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/more_screen.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_screen.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_history_screen.dart';
import 'package:kawalo_mobile/features/ptt/ptt_module.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/presentation/screens/schedule_screen.dart';

/// Always the last Beranda card: today's attendance on top, every other
/// feature as a 3x3 grid below (admins get "Kelola" instead of "Personil").
class HomeMoreCard extends StatelessWidget {
  const HomeMoreCard({required this.onArrange, super.key});

  /// Opens "Atur Beranda"; the shell owns the layout.
  final VoidCallback onArrange;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _AttendanceHalf()),
                const SizedBox(height: 14),
                _FeatureGrid(onArrange: onArrange),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceHalf extends StatelessWidget {
  const _AttendanceHalf();

  /// `HH:MM[:SS]` to the Indonesian `HH.MM`.
  static String _hm(String time) {
    final parts = time.split(':');
    return parts.length < 2 ? time : '${parts[0]}.${parts[1]}';
  }

  Future<void> _check(BuildContext context) async {
    final module = context.read<AttendanceCheckModule?>();
    final face = context.read<FaceModule?>();
    final cubit = context.read<HomeAttendanceCubit?>();
    if (module == null || face == null) {
      AppSnackbar.showInProgress(context);
      return;
    }
    final navigator = Navigator.of(context);
    final exit = await navigator.push(
      AttendanceCheckScreen.route(
        module: module,
        faceRepository: face.repository,
      ),
    );
    unawaited(cubit?.load());
    switch (exit) {
      case AttendanceCheckExit.openAttendanceList:
        navigator.push(AttendanceScreen.route());
      case AttendanceCheckExit.openSchedule:
        navigator.push(ScheduleScreen.route());
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final state = context.watch<HomeAttendanceCubit?>()?.state;
    final scheduleState = context.watch<ScheduleCubit?>()?.state;
    void check() => unawaited(_check(context));

    String subtitle;
    Widget button;
    String? caption;
    switch (state) {
      case HomeAttendanceLoading():
        subtitle = 'Memuat jadwal…';
        button = AppTaskButton(
          label: 'Memuat…',
          tone: tones.abs,
          isLoading: true,
          onPressed: check,
        );
      case HomeAttendanceLoaded(:final plan) when plan.slot != null:
        final slot = plan.slot!;
        subtitle =
            '${slot.shiftName} ${_hm(slot.startTime)}–${_hm(slot.endTime)}';
        switch (plan.action) {
          case AttendanceAction.checkIn:
            button = AppTaskButton(
              label: 'Check-in dengan Wajah',
              icon: Icons.face_outlined,
              tone: tones.abs,
              onPressed: check,
            );
            final place = slot.locationName;
            caption = place == null || place.isEmpty
                ? 'Hadapkan wajah ke kamera di titik absen'
                : 'Titik absen: $place';
          case AttendanceAction.checkOut:
            button = AppTaskButton(
              label: 'Check-out dengan Wajah',
              icon: Icons.face_outlined,
              tone: tones.abs,
              onPressed: check,
            );
            caption =
                'Masuk ${_hm(slot.checkin ?? '')} · '
                'pulang setelah ${_hm(slot.endTime)}';
          case null:
            button = const AppTaskButton(
              label: 'Absensi hari ini selesai',
              icon: Icons.check_rounded,
            );
            caption =
                'Masuk ${_hm(slot.checkin ?? '-')} · '
                'Pulang ${_hm(slot.checkout ?? '-')}';
        }
      case HomeAttendanceLoaded():
        subtitle = 'Tidak ada jadwal hari ini';
        button = const AppTaskButton(label: 'Tidak ada jadwal');
        if (scheduleState is ScheduleLoaded) {
          final next = nextShiftSubtitle(
            scheduleState.schedules,
            DateTime.now(),
          );
          caption = 'Jadwal berikutnya: $next';
        }
      case HomeAttendanceFailed() || null:
        subtitle = 'Status absen belum termuat';
        button = AppTaskButton(
          label: 'Absen dengan Wajah',
          icon: Icons.face_outlined,
          tone: tones.abs,
          onPressed: check,
        );
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tones.line)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTaskCardHeader(
            icon: Icons.face_outlined,
            title: 'Absensi',
            subtitle: subtitle,
            tone: tones.abs,
          ),
          const SizedBox(height: 10),
          button,
          if (caption != null) ...[
            const SizedBox(height: 10),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: AppTheme.monoFigures.copyWith(
                color: tones.ink2,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onArrange});

  final VoidCallback onArrange;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final isAdmin =
        context.watch<UserSessionCubit?>()?.state?.isAdminRole ?? false;
    void push(Route<void> route) => Navigator.of(context).push(route);

    final tiles = <AppFeatureTile>[
      AppFeatureTile(
        icon: Icons.menu_book_outlined,
        label: 'Buku Tamu',
        onTap: () => push(GuestScreen.route()),
      ),
      AppFeatureTile(
        icon: Icons.calendar_month_outlined,
        label: 'Jadwal',
        onTap: () => push(ScheduleScreen.route()),
      ),
      AppFeatureTile(
        icon: Icons.info_outline_rounded,
        label: 'Informasi',
        onTap: () => push(InformationScreen.route()),
      ),
      AppFeatureTile(
        icon: Icons.history_rounded,
        label: 'Riwayat PTT',
        onTap: () => push(
          PttHistoryScreen.route(
            PttModule.createRecordingRepository(
              apiClient: context.read<ApiClient>(),
            ),
          ),
        ),
      ),
      AppFeatureTile(
        icon: Icons.schedule_rounded,
        label: 'Riwayat Absen',
        onTap: () => push(AttendanceScreen.route()),
      ),
      AppFeatureTile(
        icon: Icons.bar_chart_rounded,
        label: 'Operasional',
        onTap: () => push(OperationalScreen.route()),
      ),
      if (isAdmin)
        AppFeatureTile(
          icon: Icons.shield_outlined,
          label: 'Kelola',
          onTap: () => push(ManageScreen.route()),
        )
      else
        AppFeatureTile(
          icon: Icons.group_outlined,
          label: 'Personil',
          onTap: () => push(PersonnelScreen.route()),
        ),
      AppFeatureTile(
        icon: Icons.person_outline_rounded,
        label: 'Akun',
        onTap: () => push(MoreScreen.route()),
      ),
      AppFeatureTile(
        icon: Icons.settings_outlined,
        label: 'Atur Beranda',
        onTap: onArrange,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FITUR LAIN',
          style: TextStyle(
            color: tones.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.84,
          ),
        ),
        const SizedBox(height: 10),
        for (var row = 0; row < tiles.length; row += 3) ...[
          if (row > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = row; i < row + 3; i++) ...[
                  if (i > row) const SizedBox(width: 8),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
