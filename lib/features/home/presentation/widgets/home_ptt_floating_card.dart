import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_channel_screen.dart';

/// Quick-access card yang disematkan pada Dashboard Kawalo Home,
/// memungkinkan petugas keamanan langsung melihat status saluran PTT dan
/// membuka layar taktis.
class HomePttFloatingCard extends StatelessWidget {
  const HomePttFloatingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pttCubit = context.watch<PttCubit?>();

    if (pttCubit == null) {
      return const SizedBox.shrink();
    }

    final state = pttCubit.state;

    Color cardColor;
    Color accentColor;
    String title;
    String subtitle;
    IconData icon;

    if (state is PttTransmitting) {
      cardColor = colorScheme.errorContainer;
      accentColor = colorScheme.error;
      title = 'Anda Sedang Berbicara';
      subtitle = 'Transmisi audio aktif di seluruh regu';
      icon = Icons.mic_rounded;
    } else if (state is PttListening) {
      cardColor = colorScheme.tertiaryContainer;
      accentColor = colorScheme.onTertiaryContainer;
      final speakerName = state.floorState.speaker?.name ?? 'Petugas';
      title = 'Mendengarkan: $speakerName';
      subtitle = 'Audio langsung diputar ke speaker';
      icon = Icons.volume_up_rounded;
    } else {
      cardColor = colorScheme.surfaceContainerHigh;
      accentColor = colorScheme.primary;
      title = 'Walkie-Talkie Taktis';
      subtitle = '${state.channel.memberCount} Anggota Terhubung';
      icon = Icons.radio_rounded;
    }

    return Semantics(
      button: true,
      label: 'Buka Walkie-Talkie Taktis',
      hint: 'Ketuk untuk membuka kontrol saluran PTT penuh',
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            AppPageRoute.forwardBackward<void>(
              builder: (_) => BlocProvider.value(
                value: pttCubit,
                child: const PttChannelScreen(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: AppStateLayer.minTouchTarget,
                  height: AppStateLayer.minTouchTarget,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
