import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_link.dart';

/// Komponen dasar modal bottom sheet filter dengan arsitektur slot konsisten:
/// - Header: Judul dan tombol Reset bergaris bawah ([AppTextLink])
/// - Subtitle (opsional): Label deskripsi atau judul seksi
/// - Slot [child]: Konten filter dinamis yang dapat disesuaikan per kebutuhan
/// - Footer: Tombol aksi selebar layar ([AppButton], default: "Terapkan")
class AppFilterBottomSheet extends StatelessWidget {
  /// Membuat instance [AppFilterBottomSheet].
  const AppFilterBottomSheet({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.headerChild,
    this.resetLabel = 'Reset',
    this.isResetEnabled = false,
    this.onReset,
    this.resetSemanticLabel,
    this.applyLabel = 'Terapkan',
    this.isApplyEnabled = true,
    this.onApply,
    this.applySemanticLabel,
    this.isScrollable = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space300,
    ),
    this.isRoot = true,
    this.animateSize = false,
    this.expand = false,
  });

  /// Judul header di sisi kiri atas.
  final String title;

  /// Subtitle atau judul seksi filter (opsional).
  final String? subtitle;

  /// Widget tambahan yang ditempatkan di bawah header dan bersifat sticky
  /// (tidak ikut ter-scroll bersama [child]).
  final Widget? headerChild;

  /// Label teks tombol reset (default: 'Reset').
  final String resetLabel;

  /// Menentukan apakah tombol reset aktif dan dapat diklik.
  final bool isResetEnabled;

  /// Callback saat tombol reset ditekan.
  final VoidCallback? onReset;

  /// Label semantik aksesibilitas untuk tombol reset.
  final String? resetSemanticLabel;

  /// Label teks tombol aksi utama di bagian bawah (default: 'Terapkan').
  final String applyLabel;

  /// Menentukan apakah tombol terapkan aktif dan dapat diklik.
  final bool isApplyEnabled;

  /// Callback saat tombol terapkan ditekan.
  final VoidCallback? onApply;

  /// Label semantik aksesibilitas untuk tombol terapkan.
  final String? applySemanticLabel;

  /// Menentukan apakah slot konten otomatis dibungkus scroll view vertikal.
  final bool isScrollable;

  /// Padding untuk area konten (default: horizontal 24dp).
  final EdgeInsetsGeometry contentPadding;

  /// Menentukan apakah widget ini bertindak sebagai root sheet (membungkus
  /// SafeArea, AnimatedSize, dan padding vertikal luar). Disetel `false` jika
  /// disematkan dalam multi-view sheet agar tidak terjadi padding ganda.
  final bool isRoot;

  /// Slot widget konten filter yang berubah-ubah.
  final Widget child;

  /// Menentukan apakah ukuran kontainer menganimasikan perubahan dimensi
  /// kontennya (default: `false` agar tombol Terapkan tidak bergerak).
  final bool animateSize;

  /// Menentukan apakah lembar filter harus mengisi tinggi penuh yang tersedia
  /// (tinggi tetap/terkunci) dan menyematkan tombol aksi di bagian paling bawah.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasized = theme.typography.emphasized;
    final isReducedMotion = AppMotion.isReducedMotion(context);

    Widget buildLayout(BoxConstraints constraints) {
      final isFinite = constraints.maxHeight.isFinite;
      final screenHeight = MediaQuery.sizeOf(context).height;
      final double? targetHeight;
      if (expand) {
        if (isFinite) {
          targetHeight = constraints.maxHeight;
        } else if (screenHeight > 0) {
          targetHeight = screenHeight * 0.85;
        } else {
          targetHeight = null;
        }
      } else {
        targetHeight = null;
      }

      final Widget middleSlot;
      if (isScrollable) {
        final scrollView = LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (expand && viewportConstraints.maxHeight.isFinite)
                      ? viewportConstraints.maxHeight
                      : 0.0,
                ),
                child: child,
              ),
            );
          },
        );

        if (expand && targetHeight != null) {
          middleSlot = Expanded(child: scrollView);
        } else if (isFinite) {
          middleSlot = Flexible(child: scrollView);
        } else {
          middleSlot = scrollView;
        }
      } else {
        if (expand && targetHeight != null) {
          middleSlot = Expanded(child: child);
        } else {
          middleSlot = child;
        }
      }

      final content = Padding(
        padding: contentPadding,
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Baris Teks Link (Judul + Reset) ──────────────────────
            AppTextLink(
              title: title,
              linkText: resetLabel,
              onPressed: isResetEnabled ? onReset : null,
              semanticLabel:
                  resetSemanticLabel ??
                  (isResetEnabled
                      ? '$resetLabel $title'
                      : 'Filter $title dalam kondisi default'),
            ),

            if (subtitle != null) ...[
              AppSpacing.vGapSm,
              Text(
                subtitle!,
                style: emphasized.titleMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.vGapXs,
            ] else ...[
              AppSpacing.vGapSm,
            ],

            ?headerChild,

            // ── Slot Filter Dinamis (Scrollable) ───────────────────────────
            middleSlot,

            AppSpacing.vGap300,

            // ── Tombol Terapkan (Sticky di Bawah) ──────────────────────────
            SizedBox(
              width: double.infinity,
              child: AppButton(
                size: AppButtonSize.md,
                shape: AppButtonShape.square,
                enabled: isApplyEnabled,
                semanticLabel: applySemanticLabel ?? '$applyLabel filter',
                onPressed: isApplyEnabled ? onApply : null,
                child: Text(applyLabel, style: typeScale.titleMedium),
              ),
            ),
          ],
        ),
      );

      if (targetHeight != null) {
        return SizedBox(height: targetHeight, child: content);
      }

      return content;
    }

    final body = LayoutBuilder(
      builder: (context, constraints) => buildLayout(constraints),
    );

    if (!isRoot) {
      return body;
    }

    final wrappedBody = animateSize
        ? ClipRect(
            child: AnimatedSize(
              duration: isReducedMotion ? Duration.zero : AppMotion.long2,
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: body,
            ),
          )
        : body;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space100,
            bottom: AppSpacing.space300,
          ),
          child: wrappedBody,
        ),
      ),
    );
  }
}

/// Menampilkan bottom sheet filter generik berbasis slot.
Future<T?> showAppFilterBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool showDragHandle = true,
  bool enableDrag = true,
  bool barrierDismissible = true,
  double? maxHeight,
  double maxHeightFactor = 0.85,
}) {
  return showAppBottomSheet<T>(
    context: context,
    showDragHandle: showDragHandle,
    enableDrag: enableDrag,
    barrierDismissible: barrierDismissible,
    maxHeight: maxHeight,
    maxHeightFactor: maxHeightFactor,
    child: child,
  );
}
