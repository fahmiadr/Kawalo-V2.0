import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_history_screen.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_channel_header.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_member_list.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/tactical_ptt_button.dart';
import 'package:kawalo_mobile/features/ptt/ptt_module.dart';

class PttChannelScreen extends StatefulWidget {
  const PttChannelScreen({super.key});

  static Route<void> route(PttCubit cubit) =>
      AppPageRoute.forwardBackward<void>(
        settings: const RouteSettings(name: AppRouteNames.ptt),
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider(
              create: (_) => PttMembersCubit(
                repository: PttModule.createMemberRepository(
                  apiClient: context.read<ApiClient>(),
                ),
                ptt: cubit,
              ),
            ),
          ],
          child: const PttChannelScreen(),
        ),
      );

  @override
  State<PttChannelScreen> createState() => _PttChannelScreenState();
}

class _PttChannelScreenState extends State<PttChannelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PttCubit>().checkAndRequestMicrophonePermission();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);

    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppBar(
        title: const PttChannelHeader(),
        backgroundColor: tones.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Everything but the PTT button scrolls, so the button stays
            // reachable however long the member list gets on a small phone.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocBuilder<PttCubit, PttState>(
                      builder: (context, state) =>
                          _FloorBanner(state: state, tones: tones),
                    ),
                    const SizedBox(height: 20),
                    const PttMemberList(),
                    const SizedBox(height: 12),
                    AppTaskButton(
                      label: 'Riwayat PTT',
                      icon: Icons.history_rounded,
                      variant: AppTaskButtonVariant.secondary,
                      size: AppTaskButtonSize.medium,
                      onPressed: () => Navigator.of(context).push(
                        PttHistoryScreen.route(
                          PttModule.createRecordingRepository(
                            apiClient: context.read<ApiClient>(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tombol headset atau tombol samping HP juga bisa '
                      'dipakai untuk bicara saat layar mati.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tones.ink2,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: TacticalPttButton(size: 130),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of floor status above the member list.
class _FloorBanner extends StatelessWidget {
  const _FloorBanner({required this.state, required this.tones});

  final PttState state;
  final KawaloTones tones;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final (
      IconData icon,
      String title,
      String subtitle,
      Color fg,
      Color bg,
    ) = switch (state) {
      PttTransmitting() => (
        Icons.graphic_eq_rounded,
        'Anda sedang bicara',
        'Suara Anda terdengar di seluruh regu.',
        tones.ptt.on,
        tones.ptt.color,
      ),
      PttListening() => (
        Icons.volume_up_rounded,
        '${state.floorState.speaker?.name ?? 'Rekan'} sedang bicara',
        state.floorState.speaker?.roleLabel ?? 'Tunggu sampai selesai.',
        tones.ptt.color,
        tones.ptt.soft,
      ),
      PttRequestingFloor() => (
        Icons.hourglass_top_rounded,
        'Meminta giliran…',
        'Menunggu jawaban server.',
        tones.ink,
        tones.surface2,
      ),
      PttFloorDenied(:final reason)
          when reason == 'PERMISSION_DENIED' ||
              reason == 'MICROPHONE_PERMISSION_REQUIRED' =>
        (
          Icons.mic_off_rounded,
          'Izin mikrofon diperlukan',
          'Izinkan mikrofon agar bisa bicara di walkie-talkie.',
          tones.sos.color,
          tones.sos.soft,
        ),
      PttFloorDenied() => (
        Icons.block_rounded,
        'Giliran sedang dipakai',
        'Rekan lain sedang bicara. Lepas tombol dan coba lagi.',
        tones.sos.color,
        tones.sos.soft,
      ),
      PttReconnecting() => (
        Icons.sync_rounded,
        'Menyambung ulang…',
        'Otomatis tersambung saat sinyal kembali.',
        tones.warn,
        tones.warnSoft,
      ),
      _ => (
        Icons.check_circle_outline_rounded,
        'Kanal siap',
        'Tahan tombol di bawah untuk bicara.',
        tones.ink,
        tones.surface,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tones.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
