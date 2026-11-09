import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/actionable_error/actionable_error_data.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

// Private Atomic Slot Molecules (Arsitektur 6-Slot Terpadu)
// -----------------------------------------------------------------------------

class ActionableErrorSlotContent extends StatelessWidget {
  const ActionableErrorSlotContent({
    required this.data,
    this.isCompact = false,
    super.key,
  });

  final AppActionableErrorData data;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isCompact) const Spacer(),

        // ── Slot 1: Molecule Badge Ikon Semantik ─────────────────────────────
        _ErrorIconSlot(
          isUnexpected: data.isUnexpected,
          icon: data.icon,
          customIcon: data.customIcon,
        ),
        AppSpacing.vGap300,

        // ── Slot 2 & 3: Molecule Judul dan Deskripsi Masalah ────────────────
        _ErrorHeaderSlot(
          title: data.title,
          message: data.message,
          isCompact: isCompact,
        ),

        // ── Slot 4: Troubleshooting Slot ─────────────────────────────────────
        if (data.hasTroubleshooting) ...[
          AppSpacing.vGap300,
          _ErrorTroubleshootingSlot(
            tips: data.troubleshootingTips,
          ),
        ],

        // ── Slot 5: Technical Detail Slot (Unexpected Error) ─────────────────
        if (data.hasTechnicalDetails) ...[
          AppSpacing.vGap200,
          _ErrorTechnicalDetailsSlot(
            details: data.technicalDetails!,
          ),
        ],

        if (!isCompact) const Spacer(),
        AppSpacing.vGap300,

        // ── Slot 6: Actions Slot (Menggunakan AppButton bawaan minTouchTarget)
        _ErrorActionsSlot(
          primaryStyle: data.primaryActionStyle,
          secondaryStyle: data.secondaryActionStyle,
          primaryLabel: data.primaryActionLabel,
          onPrimary: data.onPrimaryAction,
          primaryDecoration: data.primaryButtonDecoration,
          secondaryLabel: data.secondaryActionLabel,
          onSecondary: data.onSecondaryAction,
          secondaryDecoration: data.secondaryButtonDecoration,
        ),
      ],
    );
  }
}

/// Slot 1: Molecule Badge Ikon Semantik
class _ErrorIconSlot extends StatelessWidget {
  const _ErrorIconSlot({
    required this.isUnexpected,
    this.icon,
    this.customIcon,
  });

  final String? icon;
  final Widget? customIcon;
  final bool isUnexpected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);

    final Color badgeBg;
    final Color iconColor;

    if (isUnexpected) {
      badgeBg = colorScheme.errorContainer;
      iconColor = colorScheme.onErrorContainer;
    } else {
      badgeBg = colorScheme.secondaryContainer;
      iconColor = colorScheme.onSecondaryContainer;
    }

    final effectiveIcon = customIcon ??
        AppSvgIcon(
          icon ?? KawaloVectors.alertSquareFilled,
          size: 40,
          color: iconColor,
        );

    return ExcludeSemantics(
      child: Container(
        width: 80,
        height: 80,
        decoration: ShapeDecoration(
          color: badgeBg,
          shape: AppShape.extraLarge,
        ),
        child: Center(
          child: effectiveIcon,
        ),
      ),
    );
  }
}

/// Slot 2 & 3: Molecule Judul dan Deskripsi Masalah Terstruktur
class _ErrorHeaderSlot extends StatelessWidget {
  const _ErrorHeaderSlot({
    required this.title,
    required this.message,
    required this.isCompact,
  });

  final String title;
  final String message;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: (isCompact
                    ? emphasizedScale.titleLarge
                    : emphasizedScale.headlineSmall)
                .copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
        AppSpacing.vGap150,
        Text(
          message,
          style: typeScale.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Slot 4: Molecule Troubleshooting Box Terstruktur (Informational Callout).
///
/// Menggunakan [Container] dengan latar `surfaceContainerHigh` dan batas
/// `outlineVariant` (alih-alih `AppCard`) agar berfungsi murni sebagai
/// kontainer instruksional statis tanpa semantik kartu interaktif, serta
/// mempertahankan kontras tonal yang stabil di seluruh modalitas (terutama
/// saat disematkan di dalam dialog atau viewfinder kamera).
class _ErrorTroubleshootingSlot extends StatelessWidget {
  const _ErrorTroubleshootingSlot({
    required this.tips,
  });

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space200),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: AppSvgIcon(
                  KawaloVectors.repairFilled,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.hGap100,
              Expanded(
                child: Text(
                  'Cara mengatasi:',
                  style: emphasizedScale.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap150,
          for (var i = 0; i < tips.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: emphasizedScale.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tips[i],
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Slot 5: Molecule Detail Teknis Diagnostik (Accordion Interaktif)
class _ErrorTechnicalDetailsSlot extends StatefulWidget {
  const _ErrorTechnicalDetailsSlot({
    required this.details,
  });

  final String details;

  @override
  State<_ErrorTechnicalDetailsSlot> createState() =>
      _ErrorTechnicalDetailsSlotState();
}

class _ErrorTechnicalDetailsSlotState
    extends State<_ErrorTechnicalDetailsSlot> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _isExpanded,
          child: AppTappable(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppStateLayer.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space100,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _isExpanded
                            ? 'Sembunyikan detail teknis'
                            : 'Lihat detail teknis',
                        style: typeScale.labelMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.hGap50,
                    ExcludeSemantics(
                      child: AppSvgIcon(
                        _isExpanded
                            ? KawaloVectors.arrowUp01
                            : KawaloVectors.arrowDown01,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isExpanded) ...[
          AppSpacing.vGap100,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space150),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.borderSmall,
            ),
            child: SelectableText(
              widget.details,
              style: typeScale.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Slot 6: Molecule Tombol Aksi Primer & Sekunder
class _ErrorActionsSlot extends StatelessWidget {
  const _ErrorActionsSlot({
    required this.primaryStyle,
    required this.secondaryStyle,
    this.primaryLabel,
    this.onPrimary,
    this.primaryDecoration,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryDecoration,
  });

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final AppButtonColor primaryStyle;
  final AppButtonDecoration? primaryDecoration;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AppButtonColor secondaryStyle;
  final AppButtonDecoration? secondaryDecoration;

  @override
  Widget build(BuildContext context) {
    final hasPrimary = primaryLabel != null && onPrimary != null;
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    if (!hasPrimary && !hasSecondary) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPrimary)
          AppButton(
            size: AppButtonSize.md,
            style: primaryStyle,
            decoration: primaryDecoration,
            onPressed: onPrimary,
            child: Text(primaryLabel!),
          ),
        if (hasPrimary && hasSecondary) AppSpacing.vGap150,
        if (hasSecondary)
          AppButton(
            size: AppButtonSize.md,
            style: secondaryStyle,
            decoration: secondaryDecoration,
            onPressed: onSecondary,
            child: Text(secondaryLabel!),
          ),
      ],
    );
  }
}
