import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Selection
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Selection components and types
// directly from package `material_3_expressive` without custom modifications.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3ESelection,
        M3ESelectionAppBar,
        M3ESelectionController,
        M3ESelectionFlip,
        M3ESelectionLeading,
        M3ESelectionScope,
        M3ESelectionTheme;

/// Alias untuk [M3ESelection] agar selaras dengan penamaan standar Kawalo.
typedef AppSelection = M3ESelection;

/// Alias untuk [M3ESelectionController] agar selaras dengan penamaan Kawalo.
typedef AppSelectionController = M3ESelectionController;

/// Alias untuk [M3ESelectionFlip] agar selaras dengan penamaan Kawalo.
typedef AppSelectionFlip = M3ESelectionFlip;

/// Alias untuk [M3ESelectionLeading] agar selaras dengan penamaan Kawalo.
typedef AppSelectionLeading = M3ESelectionLeading;

/// Alias untuk [M3ESelectionScope] agar selaras dengan penamaan Kawalo.
typedef AppSelectionScope = M3ESelectionScope;

/// Alias untuk [M3ESelectionTheme] agar selaras dengan penamaan Kawalo.
typedef AppSelectionTheme = M3ESelectionTheme;

/// Custom Material 3 Expressive Selection App Bar untuk Kawalo Mobile.
///
/// Mengimplementasikan [PreferredSizeWidget] sehingga dapat langsung dipasang
/// pada slot `appBar` milik [Scaffold] tanpa modifikasi tata letak luar.
///
/// Secara otomatis menyinkronkan tinggi mode kontekstual dengan tinggi [idle]:
/// - Jika [idle] memiliki tinggi > 64dp (misalnya dengan search bar, 140dp),
///   baris "Pilih semua" diaktifkan dan tingginya disesuaikan (76dp) sehingga
///   tinggi total bar kontekstual (64 + 76 = 140dp) tepat sama dengan [idle].
/// - Jika [idle] memiliki tinggi <= 64dp (misalnya tanpa search bar, 64dp),
///   baris "Pilih semua" disembunyikan sehingga tinggi total bar kontekstual
///   tepat 64dp.
class AppSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Membuat instance [AppSelectionAppBar].
  const AppSelectionAppBar({
    required this.idle,
    required this.controller,
    super.key,
    this.itemCount,
    this.actions = const <Widget>[],
    this.selectAllLabel = 'Pilih semua',
    this.showSelectAll,
    this.onClear,
    this.onAllSelected,
    this.theme,
  });

  /// Widget app bar pada kondisi normal ketika tidak ada item yang dipilih
  /// (misalnya [AppHomeAppBar]).
  final PreferredSizeWidget idle;

  /// Kontroler seleksi untuk melacak status dan indeks item yang dipilih.
  final AppSelectionController controller;

  /// Jumlah total item untuk perhitungan kontrol pilih semua (select-all).
  final int? itemCount;

  /// Daftar widget aksi kontekstual di sisi trailing (misalnya tombol hapus).
  final List<Widget> actions;

  /// Label teks di samping kotak centang pilih semua.
  final String selectAllLabel;

  /// Menentukan apakah baris 'Pilih semua' ditampilkan pada mode seleksi.
  ///
  /// Jika bernilai `null`, visibilitas baris ini ditentukan otomatis
  /// berdasarkan tinggi [idle]:
  /// - `true` jika tinggi [idle] > [AppHomeAppBar.defaultPreferredHeight]
  ///   (64dp)
  /// - `false` jika tinggi [idle] <= 64dp
  final bool? showSelectAll;

  /// Callback kustom ketika tombol close / batal silang ditekan.
  final VoidCallback? onClear;

  /// Callback ketika status centang pilih semua berubah.
  final ValueChanged<bool>? onAllSelected;

  /// Tema kustom untuk komponen seleksi.
  final AppSelectionTheme? theme;

  @override
  Size get preferredSize {
    final totalHeight = idle.preferredSize.height;
    final isExpanded = totalHeight > AppHomeAppBar.defaultPreferredHeight;
    final effectiveShowSelectAll = showSelectAll ?? isExpanded;
    if (effectiveShowSelectAll && !isExpanded && controller.isSelectionMode) {
      final selectHeight = theme?.selectAllHeight ?? 48.0;
      return Size.fromHeight(totalHeight + selectHeight);
    }
    return idle.preferredSize;
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = idle.preferredSize.height;
    final isExpanded = totalHeight > AppHomeAppBar.defaultPreferredHeight;
    final effectiveShowSelectAll = showSelectAll ?? isExpanded;

    final calculatedSelectAllHeight = isExpanded
        ? totalHeight - AppHomeAppBar.defaultPreferredHeight
        : (theme?.selectAllHeight ?? 48.0);

    final effectiveTheme =
        (theme ?? M3ESelectionTheme.defaults).copyWith(
      selectAllHeight: calculatedSelectAllHeight,
    );

    return M3ESelectionAppBar(
      idle: idle,
      controller: controller,
      itemCount: itemCount,
      actions: actions,
      selectAllLabel: selectAllLabel,
      showSelectAll: effectiveShowSelectAll,
      onClear: onClear,
      onAllSelected: onAllSelected,
      theme: effectiveTheme,
    );
  }
}
