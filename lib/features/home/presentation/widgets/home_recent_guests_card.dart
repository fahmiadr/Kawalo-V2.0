import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

/// Data model representasi riwayat tamu terakhir pada beranda.
class RecentGuestItem {
  /// Membuat instance [RecentGuestItem].
  const RecentGuestItem({
    required this.identifier,
    required this.location,
    required this.timestamp,
    required this.iconPath,
  });

  /// Nomor kendaraan / identitas tamu (misal: "CN 10719", "GRAB CAR").
  final String identifier;

  /// Nama gerbang / pos checkpoint (misal: "JKN Veranda").
  final String location;

  /// Waktu kedatangan / pencatatan tamu.
  final String timestamp;

  /// Path aset SVG ikon berwarna untuk jenis tamu / kendaraan.
  final String iconPath;
}

/// Komponen kartu "Tamu Terakhir" dengan carousel multi-halaman
/// dan indikator titik.
class HomeRecentGuestsCard extends StatefulWidget {
  /// Membuat instance [HomeRecentGuestsCard].
  const HomeRecentGuestsCard({super.key, this.guestPages, this.onTapItem});

  /// Daftar halaman data tamu.
  final List<List<RecentGuestItem>>? guestPages;

  /// Callback saat salah satu item tamu ditekan.
  final void Function(RecentGuestItem item)? onTapItem;

  @override
  State<HomeRecentGuestsCard> createState() => _HomeRecentGuestsCardState();
}

class _HomeRecentGuestsCardState extends State<HomeRecentGuestsCard> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<List<RecentGuestItem>> _defaultPages = [
    [
      RecentGuestItem(
        identifier: 'CN 10719',
        location: 'JKN Veranda',
        timestamp: '29 Jun 2026 23:49',
        iconPath: KawaloColorVectors.cardTag1,
      ),
      RecentGuestItem(
        identifier: 'GRAB CAR',
        location: 'JKN Veranda',
        timestamp: '29 Jun 2026 06:49',
        iconPath: KawaloColorVectors.cardTag2,
      ),
      RecentGuestItem(
        identifier: 'CB 3063',
        location: 'JKN Veranda',
        timestamp: '28 Jun 2026 04:21',
        iconPath: KawaloColorVectors.cardTag1,
      ),
    ],
    [
      RecentGuestItem(
        identifier: 'B 1234 ABC',
        location: 'Pos Utama',
        timestamp: '28 Jun 2026 02:15',
        iconPath: KawaloColorVectors.cardTag2,
      ),
      RecentGuestItem(
        identifier: 'GO-JEK',
        location: 'Pos Barat',
        timestamp: '27 Jun 2026 21:30',
        iconPath: KawaloColorVectors.guestValidation,
      ),
      RecentGuestItem(
        identifier: 'D 5678 EFG',
        location: 'Pos Timur',
        timestamp: '27 Jun 2026 18:04',
        iconPath: KawaloColorVectors.cardTag1,
      ),
    ],
    [
      RecentGuestItem(
        identifier: 'KURIR J&T',
        location: 'JKN Veranda',
        timestamp: '27 Jun 2026 14:22',
        iconPath: KawaloColorVectors.guestValidation,
      ),
      RecentGuestItem(
        identifier: 'B 9999 VIP',
        location: 'Pos Utama',
        timestamp: '26 Jun 2026 11:10',
        iconPath: KawaloColorVectors.cardTag2,
      ),
      RecentGuestItem(
        identifier: 'TAXI BLUEBIRD',
        location: 'JKN Veranda',
        timestamp: '26 Jun 2026 09:45',
        iconPath: KawaloColorVectors.cardTag1,
      ),
    ],
    [
      RecentGuestItem(
        identifier: 'TAMU DIREKSI',
        location: 'Lobi Utama',
        timestamp: '25 Jun 2026 16:00',
        iconPath: KawaloColorVectors.guestValidation,
      ),
      RecentGuestItem(
        identifier: 'B 8888 XYZ',
        location: 'Pos Selatan',
        timestamp: '25 Jun 2026 13:12',
        iconPath: KawaloColorVectors.cardTag1,
      ),
      RecentGuestItem(
        identifier: 'GRAB FOOD',
        location: 'JKN Veranda',
        timestamp: '25 Jun 2026 12:05',
        iconPath: KawaloColorVectors.cardTag2,
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final pages = widget.guestPages ?? _defaultPages;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Container Kartu Tamu Terakhir ──────────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.borderMedium,
            boxShadow: AppElevation.shadowLevel1,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderMedium,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Kartu ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.space150,
                    left: AppSpacing.space200,
                    right: AppSpacing.space300,
                    bottom: AppSpacing.space100,
                  ),
                  child: Row(
                    children: [
                      const AppSvgIcon.color(
                        KawaloColorVectors.guestValidation,
                        size: 32,
                        semanticLabel: 'Ikon tamu terakhir',
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          'Tamu Terakhir',
                          style: typeScale.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),

                // ── Carousel Daftar Tamu ──────────────────────────────────
                SizedBox(
                  height: 168,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, pageIndex) {
                      final items = pages[pageIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space200,
                          vertical: AppSpacing.space100,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: items.map((item) {
                            return _GuestRowItem(
                              item: item,
                              onTap: widget.onTapItem != null
                                  ? () => widget.onTapItem!(item)
                                  : null,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        AppSpacing.vGap150,

        // ── Dot Page Indicator ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: AppSpacing.paddingHorizontalXs,
              width: isSelected ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: AppRadius.borderFull,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Baris tunggal informasi tamu di dalam kartu Tamu Terakhir.
class _GuestRowItem extends StatelessWidget {
  const _GuestRowItem({required this.item, this.onTap});

  final RecentGuestItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final semanticText =
        'Tamu ${item.identifier}, lokasi ${item.location}, '
        'waktu ${item.timestamp}';

    return AppTappable(
      onTap: onTap,
      enabled: onTap != null,
      semanticLabel: semanticText,
      child: Padding(
        padding: AppSpacing.paddingVerticalXs,
        child: Row(
          children: [
            AppSvgIcon.color(
              item.iconPath,
              size: 28,
              semanticLabel: item.identifier,
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.identifier,
                    style: typeScale.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.location,
                          style: typeScale.labelSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        item.timestamp,
                        style: typeScale.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
