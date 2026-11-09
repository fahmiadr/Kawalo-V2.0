import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';

/// Pilihan tata letak susunan chip pada [AppFormChipGroup].
enum AppFormChipGroupLayout {
  /// Chips tersusun dalam baris horizontal yang dapat digeser (scrollable).
  horizontalScroll,

  /// Chips membungkus secara adaptif ke baris baru saat melebihi lebar layar.
  wrap,
}

/// Model item data untuk setiap opsi chip di dalam [AppFormChipGroup].
class AppFormChipItem<T> {
  /// Membuat instance [AppFormChipItem].
  const AppFormChipItem({
    required this.value,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.avatar,
    this.semanticLabel,
  });

  /// Nilai data unik yang direpresentasikan oleh chip ini.
  final T value;

  /// Teks label yang ditampilkan pada chip.
  final String label;

  /// Menandakan apakah chip ini sedang aktif/terpilih.
  final bool selected;

  /// Menandakan apakah chip dapat ditekan pengguna.
  final bool enabled;

  /// Widget avatar atau ikon opsional pada sisi kiri chip.
  final Widget? avatar;

  /// Label aksesibilitas pembaca layar (opsional).
  final String? semanticLabel;
}

/// Komponen formulir untuk pemilihan opsi berbasis [AppChip] filter.
///
/// Mengintegrasikan [AppFormFieldSlot] untuk keseragaman label dan pesan galat,
/// serta mendukung tata letak geser horizontal maupun bungkus multi-baris.
class AppFormChipGroup<T> extends StatelessWidget {
  /// Membuat [AppFormChipGroup] berbasis daftar data [items].
  const AppFormChipGroup({
    required this.label,
    required this.items,
    this.selectedValue,
    this.onSelected,
    this.enabled = true,
    this.isRequired = false,
    this.errorText,
    this.layout = AppFormChipGroupLayout.horizontalScroll,
    this.chipSpacing = AppSpacing.space100,
    this.chipRunSpacing = AppSpacing.space100,
    this.padding,
    this.labelStyle,
    this.trailing,
    super.key,
  }) : _customContent = null;

  /// Konstruktor fleksibel jika pemanggil ingin menyusun widget chip kustom.
  const AppFormChipGroup.slot({
    required this.label,
    required Widget child,
    this.isRequired = false,
    this.errorText,
    this.padding,
    this.labelStyle,
    this.trailing,
    super.key,
  }) : items = const [],
       selectedValue = null,
       onSelected = null,
       enabled = true,
       layout = AppFormChipGroupLayout.wrap,
       chipSpacing = AppSpacing.space100,
       chipRunSpacing = AppSpacing.space100,
       _customContent = child;

  /// Teks label field (misal: "Kategori informasi", "Jenis identitas").
  final String label;

  /// Daftar item pilihan chip.
  final List<AppFormChipItem<T>> items;

  /// Nilai terpilih saat ini untuk pencocokan otomatis terhadap [items].
  final T? selectedValue;

  /// Callback saat pengguna memilih item chip tertentu.
  final ValueChanged<T>? onSelected;

  /// Menandakan apakah grup chip interaktif dan dapat dipilih.
  final bool enabled;

  /// Menandakan apakah pilihan bersifat wajib.
  final bool isRequired;

  /// Pesan galat validasi di bawah grup chip.
  final String? errorText;

  /// Mode tata letak susunan chip (horizontal geser atau bungkus baris).
  final AppFormChipGroupLayout layout;

  /// Jarak horizontal antar chip.
  final double chipSpacing;

  /// Jarak vertikal antar baris chip saat mode wrap.
  final double chipRunSpacing;

  /// Padding luar field chip group.
  final EdgeInsetsGeometry? padding;

  /// Gaya tipografi label kustom.
  final TextStyle? labelStyle;

  /// Aksesoris opsional di sisi kanan label.
  final Widget? trailing;

  final Widget? _customContent;

  @override
  Widget build(BuildContext context) {
    final Widget chipsWidget;

    if (_customContent != null) {
      chipsWidget = _customContent;
    } else if (layout == AppFormChipGroupLayout.horizontalScroll) {
      chipsWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: items.map((item) {
            final isSelected = item.selected || item.value == selectedValue;
            final isItemEnabled = enabled && item.enabled && onSelected != null;
            Widget chipWidget = AppChip(
              type: AppChipType.filter,
              label: item.label,
              selected: isSelected,
              avatar: item.avatar,
              onPressed: isItemEnabled ? () => onSelected!(item.value) : null,
            );
            if (item.semanticLabel != null) {
              chipWidget = Semantics(
                label: item.semanticLabel,
                child: chipWidget,
              );
            }
            return Padding(
              padding: EdgeInsets.only(right: chipSpacing),
              child: chipWidget,
            );
          }).toList(),
        ),
      );
    } else {
      chipsWidget = Wrap(
        spacing: chipSpacing,
        runSpacing: chipRunSpacing,
        children: items.map((item) {
          final isSelected = item.selected || item.value == selectedValue;
          final isItemEnabled = enabled && item.enabled && onSelected != null;
          Widget chipWidget = AppChip(
            type: AppChipType.filter,
            label: item.label,
            selected: isSelected,
            avatar: item.avatar,
            onPressed: isItemEnabled ? () => onSelected!(item.value) : null,
          );
          if (item.semanticLabel != null) {
            chipWidget = Semantics(
              label: item.semanticLabel,
              child: chipWidget,
            );
          }
          return chipWidget;
        }).toList(),
      );
    }

    return AppFormFieldSlot(
      label: label,
      isRequired: isRequired,
      errorText: errorText,
      trailing: trailing,
      padding: padding,
      labelStyle: labelStyle,
      child: chipsWidget,
    );
  }
}
