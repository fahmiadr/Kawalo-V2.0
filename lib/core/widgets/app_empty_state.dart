import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Komponen state kosong Material Design 3 untuk aplikasi Kawalo.
///
/// Digunakan untuk menampilkan indikasi data belum tersedia, hasil
/// pencarian kosong, maupun pesan galat (error) dengan tata letak vertikal
/// yang konsisten, dukungan [AlwaysScrollableScrollPhysics] untuk
/// pull-to-refresh, dan aksesibilitas WCAG AA.
class AppEmptyState extends StatelessWidget {
  /// Membuat instance [AppEmptyState] standar dengan ikon kustom.
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
    this.iconSize = 64.0,
    this.action,
    this.actionLabel,
    this.onActionPressed,
    this.actionStyle = AppButtonColor.tonal,
    this.actionSize = AppButtonSize.sm,
    this.padding = const EdgeInsets.all(AppSpacing.space400),
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  /// Membuat instance [AppEmptyState] khusus hasil pencarian atau filter
  /// kosong.
  ///
  /// Menggunakan ikon bawaan [KawaloVectors.search01] dengan warna outline.
  const factory AppEmptyState.search({
    required String title,
    required String description,
    Key? key,
    double iconSize,
    Widget? action,
    String? actionLabel,
    VoidCallback? onActionPressed,
    AppButtonColor actionStyle,
    AppButtonSize actionSize,
    EdgeInsetsGeometry padding,
    ScrollPhysics physics,
  }) = _AppEmptyStateSearch;

  /// Membuat instance [AppEmptyState] khusus status kesalahan pemuatan data.
  ///
  /// Menggunakan ikon bawaan [KawaloVectors.alertSquareFilled] dengan warna
  /// error.
  const factory AppEmptyState.error({
    required String title,
    required String description,
    Key? key,
    double iconSize,
    Widget? action,
    String? retryLabel,
    VoidCallback? onRetry,
    String? actionLabel,
    VoidCallback? onActionPressed,
    AppButtonColor actionStyle,
    AppButtonSize actionSize,
    EdgeInsetsGeometry padding,
    ScrollPhysics physics,
  }) = _AppEmptyStateError;

  /// Widget ikon utama yang ditampilkan di bagian atas.
  final Widget icon;

  /// Ukuran lebar dan tinggi ikon dalam logical pixels (default: 64.0).
  final double iconSize;

  /// Judul pesan (menggunakan style `emphasized.titleMedium`).
  final String title;

  /// Penjelasan detail pesan (menggunakan style `typeScale.bodyMedium`).
  final String description;

  /// Widget aksi kustom eksplisit (misalnya tombol khusus).
  /// Mengambil prioritas lebih tinggi daripada [actionLabel].
  final Widget? action;

  /// Label teks untuk action button bawaan.
  final String? actionLabel;

  /// Callback ketika action button ditekan.
  final VoidCallback? onActionPressed;

  /// Tipe styling [AppButtonColor] untuk action button bawaan
  /// (default: [AppButtonColor.tonal]).
  final AppButtonColor actionStyle;

  /// Ukuran tombol aksi [AppButtonSize] (default: [AppButtonSize.sm]).
  final AppButtonSize actionSize;

  /// Padding di sekitar konten. Default [AppSpacing.space400] (32dp).
  final EdgeInsetsGeometry padding;

  /// Scroll physics untuk [SingleChildScrollView].
  /// Default [AlwaysScrollableScrollPhysics] agar kompatibel dengan
  /// pull-to-refresh.
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    final effectiveAction = action ??
        (actionLabel != null && onActionPressed != null
            ? AppButton(
                style: actionStyle,
                size: actionSize,
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              )
            : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics,
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            alignment: Alignment.center,
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: iconSize,
                  ),
                  child: SizedBox.square(
                    dimension: iconSize,
                    child: FittedBox(
                      child: icon,
                    ),
                  ),
                ),
                AppSpacing.vGap300,
                Text(
                  title,
                  style: emphasizedScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapSm,
                Text(
                  description,
                  style: typeScale.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (effectiveAction != null) ...[
                  AppSpacing.vGap300,
                  effectiveAction,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppEmptyStateSearch extends AppEmptyState {
  const _AppEmptyStateSearch({
    required super.title,
    required super.description,
    super.key,
    super.iconSize = 64.0,
    super.action,
    super.actionLabel,
    super.onActionPressed,
    super.actionStyle = AppButtonColor.tonal,
    super.actionSize = AppButtonSize.sm,
    super.padding,
    super.physics,
  }) : super(
          icon: const SizedBox.shrink(),
        );

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return AppEmptyState(
      icon: AppSvgIcon(
        KawaloVectors.search01,
        color: colorScheme.outline,
      ),
      iconSize: iconSize,
      title: title,
      description: description,
      action: action,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      actionStyle: actionStyle,
      actionSize: actionSize,
      padding: padding,
      physics: physics,
    );
  }
}

class _AppEmptyStateError extends AppEmptyState {
  const _AppEmptyStateError({
    required super.title,
    required super.description,
    super.key,
    super.iconSize = 64.0,
    super.action,
    String? retryLabel,
    VoidCallback? onRetry,
    String? actionLabel,
    VoidCallback? onActionPressed,
    super.actionStyle = AppButtonColor.tonal,
    super.actionSize = AppButtonSize.sm,
    super.padding,
    super.physics,
  }) : super(
          icon: const SizedBox.shrink(),
          actionLabel: actionLabel ?? retryLabel,
          onActionPressed: onActionPressed ?? onRetry,
        );

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return AppEmptyState(
      icon: AppSvgIcon(
        KawaloVectors.alertSquareFilled,
        color: colorScheme.error,
      ),
      iconSize: iconSize,
      title: title,
      description: description,
      action: action,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      actionStyle: actionStyle,
      actionSize: actionSize,
      padding: padding,
      physics: physics,
    );
  }
}
