import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_history_screen.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_channel_header.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/tactical_ptt_button.dart';
import 'package:kawalo_mobile/features/ptt/ptt_module.dart';

class PttChannelScreen extends StatefulWidget {
  const PttChannelScreen({super.key});

  static Route<void> route(PttCubit cubit) =>
      AppPageRoute.forwardBackward<void>(
        settings: const RouteSettings(name: AppRouteNames.ptt),
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const PttChannelScreen()),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Walkie-Talkie Taktis'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.md * 2),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // 1. Channel Header (Status & Anggota)
                      const PttChannelHeader(),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.icon(
                          style: AppButtonColor.tonal,
                          size: AppButtonSize.custom(
                            height: AppStateLayer.minTouchTarget,
                            hPadding: AppSpacing.space200,
                          ),
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('Riwayat Rekaman'),
                          onPressed: () => Navigator.of(context).push(
                            PttHistoryScreen.route(
                              PttModule.createRecordingRepository(
                                apiClient: context.read<ApiClient>(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 2. Active Speaker Banner / Live Status
                      Expanded(
                        child: Center(
                          child: BlocBuilder<PttCubit, PttState>(
                            builder: (context, state) {
                              String bannerTitle;
                              String bannerSubtitle;
                              Color bannerColor;
                              IconData bannerIcon;

                              if (state is PttTransmitting) {
                                bannerTitle = 'TRANSMISI AKTIF';
                                bannerSubtitle =
                                    'Mikrofon terbuka. Suara Anda terdengar di '
                                    'seluruh regu.';
                                bannerColor = colorScheme.error;
                                bannerIcon = Icons.graphic_eq_rounded;
                              } else if (state is PttListening) {
                                final speaker = state.floorState.speaker;
                                final speakerName = speaker?.name ?? 'Petugas';
                                bannerTitle = speakerName.toUpperCase();
                                bannerSubtitle = speaker == null
                                    ? 'Sedang berbicara'
                                    : 'Sedang berbicara (${speaker.roleLabel})';
                                bannerColor = colorScheme.tertiary;
                                bannerIcon = Icons.volume_up_rounded;
                              } else if (state is PttRequestingFloor) {
                                bannerTitle = 'MEMINTA JALUR...';
                                bannerSubtitle =
                                    'Menunggu balasan arbitrase dari server...';
                                bannerColor = colorScheme.primary;
                                bannerIcon = Icons.hourglass_top_rounded;
                              } else if (state is PttFloorDenied) {
                                final isPermDenied =
                                    state.reason == 'PERMISSION_DENIED' ||
                                    state.reason ==
                                        'MICROPHONE_PERMISSION_REQUIRED';
                                if (isPermDenied) {
                                  bannerTitle = 'IZIN MIKROFON DIPERLUKAN';
                                  bannerSubtitle =
                                      'Akses mikrofon dibutuhkan untuk berbicara di '
                                      'saluran Walkie-Talkie.';
                                  bannerIcon = Icons.mic_off_rounded;
                                } else {
                                  bannerTitle = 'PERMINTAAN DITOLAK';
                                  bannerSubtitle =
                                      'Jalur sedang digunakan oleh personil lain. '
                                      'Lepas tombol dan coba lagi.';
                                  bannerIcon = Icons.block_rounded;
                                }
                                bannerColor = colorScheme.error;
                              } else if (state is PttReconnecting) {
                                bannerTitle = 'MENYAMBUNG ULANG';
                                bannerSubtitle =
                                    'Koneksi seluler terputus. '
                                    'Menginisiasi sambungan cadangan...';
                                bannerColor = colorScheme.outline;
                                bannerIcon = Icons.sync_rounded;
                              } else {
                                // PttIdle
                                bannerTitle = 'SALURAN SIAP';
                                bannerSubtitle =
                                    'Tekan dan tahan tombol PTT di bawah '
                                    'untuk berbicara.';
                                bannerColor = colorScheme.primary;
                                bannerIcon = Icons.check_circle_outline_rounded;
                              }

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: bannerColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: bannerColor.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      bannerIcon,
                                      size: 44,
                                      color: bannerColor,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      bannerTitle,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: bannerColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      bannerSubtitle,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // 3. Oversized Glove-Friendly Tactical PTT Button
                      const TacticalPttButton(size: 130),

                      const SizedBox(height: AppSpacing.lg),

                      // 4. Tactical Guidance Footer
                      Text(
                        'Anda juga dapat menggunakan tombol headset fisik atau '
                        'tombol samping pada ponsel rugged saat layar mati di dalam '
                        'saku.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
