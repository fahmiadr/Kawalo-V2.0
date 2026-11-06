import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_shortcut_card.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_text_link.dart';

/// Komponen bagian "Manajemen" pada beranda yang menampilkan daftar
/// kartu modul manajemen dan tombol aksi tambah manajemen.
class HomeManagementSection extends StatelessWidget {
  /// Membuat instance [HomeManagementSection].
  const HomeManagementSection({
    super.key,
    this.items,
    this.showAddCard = true,
    this.onEditPressed,
    this.onAddPressed,
  });

  /// Daftar item manajemen kustom (opsional).
  final List<AppShortcutItem>? items;

  /// Menentukan apakah kartu "Tambah Manajemen" ditampilkan.
  final bool showAddCard;

  /// Callback ketika link "Edit" ditekan.
  final VoidCallback? onEditPressed;

  /// Callback ketika kartu "Tambah Manajemen" ditekan.
  final VoidCallback? onAddPressed;

  List<AppShortcutItem> _getDefaultItems(BuildContext context) {
    return [
      AppShortcutItem(
        title: 'Manajemen Shift',
        iconPath: KawaloColorVectors.personRotation3,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Manajemen Shift...',
          );
        },
      ),
      AppShortcutItem(
        title: 'Manajemen Jadwal',
        iconPath: KawaloColorVectors.calendarAdd,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Manajemen Jadwal...',
          );
        },
      ),
      AppShortcutItem(
        title: 'Manajemen Personil',
        iconPath: KawaloColorVectors.patrolAdd,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Manajemen Personil...',
          );
        },
      ),
      AppShortcutItem(
        title: 'Manajemen Grup',
        subtitle: 'Grup Personil',
        iconPath: KawaloColorVectors.groupAdd1,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Manajemen Grup...',
          );
        },
      ),
      AppShortcutItem(
        title: 'Laporan Bulanan',
        subtitle: 'Otomatisasi Laporan',
        badgeText: 'BARU!',
        iconPath: KawaloColorVectors.fileValidation,
        onTap: () {
          AppSnackbar.show(
            context,
            message: 'Membuka Laporan Bulanan...',
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveItems = items ?? _getDefaultItems(context);
    final totalCount =
        showAddCard ? effectiveItems.length + 1 : effectiveItems.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header Bagian Manajemen ────────────────────────────────────────
        AppTextLink(
          title: 'Manajemen',
          linkText: 'Edit',
          semanticLabel: 'Edit susunan manajemen',
          onPressed: onEditPressed ??
              () {
                AppSnackbar.show(
                  context,
                  message: 'Fitur pengaturan manajemen segera hadir.',
                );
              },
        ),

        AppSpacing.vGapSm,

        // ── Grid Manajemen Adaptif ─────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
            final textScaler = MediaQuery.textScalerOf(context);
            // Non-text fixed: padding vertikal 24 + icon 40 + gap 8 = 72dp
            // Text scalable: judul 24 + subtitle 16 + buffer = 50dp
            final mainAxisExtent = 76.0 + textScaler.scale(50);

            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.space150,
                mainAxisSpacing: AppSpacing.space200,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (context, index) {
                if (index < effectiveItems.length) {
                  return AppShortcutCard(item: effectiveItems[index]);
                }
                return AppAddShortcutCard(
                  label: 'Tambah Manajemen',
                  onPressed: onAddPressed ??
                      () {
                        AppSnackbar.show(
                          context,
                          message: 'Fitur Tambah Manajemen segera hadir.',
                        );
                      },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
