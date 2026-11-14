import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_round_action_button.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_card_header.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/presentation/extensions/home_card_ui_extension.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_card_body.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_screen.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_form_dialog.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';
import 'package:kawalo_mobile/features/schedule/presentation/screens/schedule_screen.dart';

/// Insiden: open count from the shared incident list (its current page, as
/// the old Beranda badge did), "Laporkan" opens the create form.
class HomeIncidentCard extends StatelessWidget {
  const HomeIncidentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final cubit = context.watch<IncidentListCubit?>();
    final state = cubit?.state;
    final loading =
        state == null || state is IncidentInitial || state is IncidentLoading;
    final open = state?.displayedIncidents.where((i) => i.isOpen).length ?? 0;

    return HomeCardBody(
      header: AppTaskCardHeader(
        icon: HomeCard.inc.icon,
        title: 'Insiden',
        subtitle: loading && open == 0
            ? 'Memuat…'
            : open > 0
            ? '$open masih terbuka'
            : 'Tidak ada yang terbuka',
        tone: tones.inc,
      ),
      children: [
        AppRoundActionButton(
          icon: Icons.photo_camera_outlined,
          label: 'Laporkan',
          tone: tones.inc,
          semanticLabel: 'Laporkan insiden',
          onPressed: () => unawaited(
            IncidentFormDialog.showCreate(context, incidentListCubit: cubit),
          ),
        ),
        const HomeCardCaption('Foto dulu, keterangan kemudian'),
        if (open > 0)
          AppTaskButton(
            label: 'Lihat $open yang terbuka',
            variant: AppTaskButtonVariant.secondary,
            size: AppTaskButtonSize.small,
            onPressed: () => Navigator.of(context).push(IncidentScreen.route()),
          ),
      ],
    );
  }
}

/// SOS and Patroli have no API yet. User decision: they look like normal
/// cards; the action only says [AppSnackbar.inProgressMessage]. No sample
/// data (no invented counts or radius).
class HomeSoonCard extends StatelessWidget {
  const HomeSoonCard({required this.card, super.key})
    : assert(card == HomeCard.sos || card == HomeCard.pat, 'SOS or Patroli');

  final HomeCard card;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final sos = card == HomeCard.sos;
    return HomeCardBody(
      header: AppTaskCardHeader(
        icon: card.icon,
        title: sos ? 'Darurat' : 'Patroli',
        subtitle: sos
            ? 'Bantuan segera dari grup'
            : 'Absen di tiap titik patroli',
        tone: card.tone(tones),
      ),
      children: [
        AppRoundActionButton(
          icon: card.icon,
          label: sos ? 'Tahan 3 detik' : 'Absen Titik',
          tone: card.tone(tones),
          semanticLabel: sos ? 'Kirim SOS' : 'Absen titik patroli',
          // A tap fires on release, so holding also lands here.
          onPressed: () => AppSnackbar.showInProgress(context),
        ),
        HomeCardCaption(
          sos
              ? 'Lepas sebelum 3 detik untuk batal'
              : 'Harus dalam radius titik patroli',
        ),
      ],
    );
  }
}

/// Optional cards added in "Atur Beranda": title, one status line, one
/// round button that opens the existing screen.
class HomeShortcutCard extends StatelessWidget {
  const HomeShortcutCard({required this.card, super.key})
    : assert(card == HomeCard.gst || card == HomeCard.sch, 'Tamu or Jadwal');

  final HomeCard card;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final guest = card == HomeCard.gst;
    final scheduleState = guest ? null : context.watch<ScheduleCubit?>()?.state;
    final status = switch (scheduleState) {
      ScheduleLoaded(:final schedules) => nextShiftSubtitle(
        schedules,
        DateTime.now(),
      ),
      ScheduleError() => 'Jadwal belum termuat',
      _ => card.description,
    };

    return HomeCardBody(
      header: AppTaskCardHeader(
        icon: card.icon,
        title: card.label,
        subtitle: status,
        tone: card.tone(tones),
      ),
      children: [
        AppRoundActionButton(
          icon: card.icon,
          label: guest ? 'Buka Buku Tamu' : 'Lihat Jadwal',
          tone: card.tone(tones),
          onPressed: () => Navigator.of(
            context,
          ).push(guest ? GuestScreen.route() : ScheduleScreen.route()),
        ),
      ],
    );
  }
}
