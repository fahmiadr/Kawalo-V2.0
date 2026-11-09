import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_section_header.dart';

/// Komponen layout slot makro yang mengintegrasikan [AppSectionHeader]
/// dan kontainer kartu / isi di bawahnya ke dalam satu kesatuan modular.
class AppFormSection extends StatelessWidget {
  /// Membuat [AppFormSection] yang membungkus konten di dalam [AppCard].
  ///
  /// Sangat cocok untuk mengelompokkan sekumpulan input (seperti di Seksi 1
  /// & 2 pada Formulir Tamu).
  const AppFormSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.cardVariant = AppCardVariant.outlined,
    this.cardPadding = const EdgeInsets.all(AppSpacing.space200),
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space50,
    ),
    this.headerToContentGap = AppSpacing.vGapSm,
    super.key,
  }) : isContained = true;

  /// Membuat [AppFormSection] tanpa kontainer kartu luar (flat / uncontained).
  ///
  /// Menampilkan [AppSectionHeader] diikuti langsung oleh [child] dengan jarak
  /// standar [AppSpacing.vGap150]. Sangat cocok untuk seksi yang memiliki
  /// kartu-kartu item atau placeholder tersendiri di dalamnya (seperti
  /// Seksi Lokasi & Seksi Foto di Informasi, atau Seksi Foto di Tamu).
  const AppFormSection.uncontained({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space50,
    ),
    this.headerToContentGap = AppSpacing.vGap150,
    super.key,
  }) : isContained = false,
       cardVariant = AppCardVariant.outlined,
       cardPadding = EdgeInsets.zero;

  /// Judul seksi formulir (misal: "Informasi tamu & identitas").
  final String title;

  /// Subjudul deskripsi konteks seksi (opsional).
  final String? subtitle;

  /// Widget opsional di sisi kanan header (misal: tombol teks atau counter).
  final Widget? trailing;

  /// Widget konten isi dari seksi ini.
  final Widget child;

  /// Menentukan apakah [child] dibungkus dalam [AppCard].
  final bool isContained;

  /// Varian kartu jika [isContained] bernilai true (default: outlined).
  final AppCardVariant cardVariant;

  /// Padding di dalam kartu jika [isContained] bernilai true.
  final EdgeInsetsGeometry cardPadding;

  /// Padding horizontal/vertikal pembungkus header.
  final EdgeInsetsGeometry headerPadding;

  /// Jarak vertikal antara header dan konten/kartu.
  final Widget headerToContentGap;

  @override
  Widget build(BuildContext context) {
    final header = AppSectionHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      padding: headerPadding,
    );

    final Widget content;
    if (isContained) {
      content = AppCard(
        variant: cardVariant,
        padding: cardPadding,
        child: child,
      );
    } else {
      content = child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [header, headerToContentGap, content],
    );
  }
}
