import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_round_action_button.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_card_header.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_card_body.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_channel_screen.dart';

/// Walkie-talkie card: hold the round button to talk (same press/release
/// calls as `TacticalPttButton`). The subtitle opens the channel screen with
/// the online members and the recording history.
class HomePttCard extends StatelessWidget {
  const HomePttCard({super.key});

  static bool _connected(PttState s) =>
      s is PttIdle ||
      s is PttRequestingFloor ||
      s is PttTransmitting ||
      s is PttListening ||
      s is PttFloorDenied;

  static void _onDenied(BuildContext context, PttFloorDenied state) {
    final permission =
        state.reason == 'PERMISSION_DENIED' ||
        state.reason == 'MICROPHONE_PERMISSION_REQUIRED';
    final speaker = state.floorState.speaker?.name;
    AppSnackbar.show(
      context,
      message: permission
          ? 'Izin mikrofon diperlukan untuk bicara.'
          : speaker == null
          ? 'Giliran sedang dipakai. Coba lagi sebentar.'
          : 'Giliran sedang dipakai $speaker. Coba lagi sebentar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final cubit = context.read<PttCubit>();

    return BlocConsumer<PttCubit, PttState>(
      listenWhen: (_, s) => s is PttFloorDenied,
      listener: (context, s) => _onDenied(context, s as PttFloorDenied),
      builder: (context, state) {
        final connected = _connected(state);
        // The server's count includes this device.
        final count = state.channel.memberCount;
        final subtitle = !connected
            ? 'Terputus'
            : count == null
            ? 'Tersambung ›'
            : '${count > 0 ? count - 1 : 0} rekan online ›';

        final header = AppTaskCardHeader(
          icon: Icons.mic_none_rounded,
          title: 'Walkie-talkie',
          subtitle: subtitle,
          tone: tones.ptt,
          onSubtitleTap: () =>
              Navigator.of(context).push(PttChannelScreen.route(cubit)),
        );

        if (!connected) {
          return HomeCardBody(
            header: header,
            top: _Banner(tones: tones),
            children: [
              AppRoundActionButton(
                icon: Icons.mic_off_outlined,
                label: 'Menyambung',
                tone: tones.ptt,
              ),
              const HomeCardCaption('Otomatis tersambung saat sinyal kembali'),
            ],
          );
        }

        final talking = state is PttTransmitting;
        final requesting = state is PttRequestingFloor;
        final listening = state is PttListening;
        final speaker = listening
            ? (state.floorState.speaker?.name ?? 'Rekan')
            : null;

        return HomeCardBody(
          header: header,
          children: [
            AppRoundActionButton(
              icon: Icons.mic_none_rounded,
              label: talking
                  ? 'Sedang bicara'
                  : requesting
                  ? 'Meminta giliran…'
                  : speaker != null
                  ? '$speaker bicara'
                  : 'Tahan untuk bicara',
              tone: tones.ptt,
              active: talking || requesting,
              dimmed: listening,
              semanticLabel: 'Tombol walkie-talkie',
              semanticHint: 'Tahan untuk bicara, lepas untuk selesai',
              onHoldStart: () => unawaited(cubit.pressPttButton()),
              onHoldEnd: () => unawaited(cubit.releasePttButton()),
            ),
            if (talking)
              const _TalkClock()
            else
              HomeCardCaption(
                listening ? 'Tunggu sampai selesai' : 'Lepas untuk selesai',
              ),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.tones});

  final KawaloTones tones;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: tones.sos.soft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(Icons.wifi_off_rounded, size: 18, color: tones.sos.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Menyambung ulang… Suara belum bisa dikirim.',
            style: TextStyle(
              color: tones.sos.color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// "0:04 · semua rekan mendengar", counted from when the floor was granted.
class _TalkClock extends StatefulWidget {
  const _TalkClock();

  @override
  State<_TalkClock> createState() => _TalkClockState();
}

class _TalkClockState extends State<_TalkClock> {
  final _since = DateTime.now();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DateTime.now().difference(_since).inSeconds;
    final clock = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: clock, style: AppTheme.monoFigures),
          const TextSpan(text: ' · semua rekan mendengar'),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(color: KawaloTones.of(context).ink2, fontSize: 14),
    );
  }
}
