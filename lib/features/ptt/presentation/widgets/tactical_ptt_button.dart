import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// Tombol pemicu PTT taktis berukuran besar (120dp) yang ramah sarung tangan
/// patroli, mematuhi standar aksesibilitas WCAG AA, dan mengimplementasikan
/// animasi pegas M3 Expressive.
class TacticalPttButton extends StatefulWidget {
  const TacticalPttButton({
    super.key,
    this.size = 120.0,
  });

  final double size;

  @override
  State<TacticalPttButton> createState() => _TacticalPttButtonState();
}

class _TacticalPttButtonState extends State<TacticalPttButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.medium4,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: AppEasing.emphasizedDecelerate,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    HapticFeedback.heavyImpact();
    if (!AppMotion.isReducedMotion(context)) {
      _pulseController.forward();
    }
    context.read<PttCubit>().pressPttButton();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!AppMotion.isReducedMotion(context)) {
      _pulseController.reverse();
    }
    context.read<PttCubit>().releasePttButton();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!AppMotion.isReducedMotion(context)) {
      _pulseController.reverse();
    }
    context.read<PttCubit>().releasePttButton();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PttCubit, PttState>(
      builder: (context, state) {
        Color buttonColor;
        Color iconColor;
        String statusLabel;
        IconData icon;
        var isPulsating = false;

        if (state is PttTransmitting) {
          buttonColor = colorScheme.error;
          iconColor = colorScheme.onError;
          statusLabel = 'Transmisi Aktif (Bicara Sekarang)';
          icon = Icons.mic_rounded;
          isPulsating = true;
        } else if (state is PttRequestingFloor) {
          buttonColor = colorScheme.primaryContainer;
          iconColor = colorScheme.onPrimaryContainer;
          statusLabel = 'Meminta Izin Bicara...';
          icon = Icons.hourglass_top_rounded;
        } else if (state is PttListening) {
          buttonColor = colorScheme.tertiaryContainer;
          iconColor = colorScheme.onTertiaryContainer;
          statusLabel = 'Mendengarkan Rekan';
          icon = Icons.volume_up_rounded;
        } else if (state is PttFloorDenied) {
          buttonColor = colorScheme.errorContainer;
          iconColor = colorScheme.onErrorContainer;
          statusLabel = 'Saluran Sedang Sibuk';
          icon = Icons.mic_off_rounded;
        } else if (state is PttReconnecting || state is PttConnecting) {
          buttonColor = colorScheme.surfaceContainerHighest;
          iconColor = colorScheme.outline;
          statusLabel = 'Menyambung Ulang...';
          icon = Icons.sync_rounded;
        } else {
          // PttIdle
          buttonColor = colorScheme.primary;
          iconColor = colorScheme.onPrimary;
          statusLabel = 'Tekan & Tahan untuk Bicara';
          icon = Icons.mic_none_rounded;
        }

        final targetSize =
            widget.size < AppStateLayer.minTouchTarget
                ? AppStateLayer.minTouchTarget
                : widget.size;

        return Semantics(
          button: true,
          label: 'Tombol Walkie Talkie PTT',
          value: statusLabel,
          hint: 'Tekan dan tahan untuk mulai berbicara, lepas untuk selesai',
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: SizedBox(
              width: targetSize + 24,
              height: targetSize + 24,
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    final scale = AppMotion.isReducedMotion(context)
                        ? 1.0
                        : _scaleAnimation.value;
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: targetSize,
                    height: targetSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: buttonColor,
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.35),
                          blurRadius: isPulsating ? 24 : 12,
                          spreadRadius: isPulsating ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: targetSize * 0.38,
                            color: iconColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state is PttTransmitting ? 'BICARA' : 'PTT',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
