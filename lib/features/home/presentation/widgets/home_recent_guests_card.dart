import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// View model of one row of the "Tamu Terakhir" card.
class RecentGuestItem {
  const RecentGuestItem({
    required this.identifier,
    required this.location,
    required this.timestamp,
    required this.iconPath,
    this.guest,
  });

  factory RecentGuestItem.fromGuest(GuestItemEntity guest) {
    final destination = guest.guestDestination?.trim() ?? '';
    final purpose = guest.guestPurpose?.trim() ?? '';
    return RecentGuestItem(
      identifier: guest.identifier,
      location: destination.isNotEmpty
          ? destination
          : (purpose.isNotEmpty ? purpose : '-'),
      timestamp: guest.displayEntryTime,
      // Same tag icon as the guest list card: the API has no per-type icon.
      iconPath: KawaloColorVectors.cardTag2,
      guest: guest,
    );
  }

  /// Guest name, or the vehicle/guest number when there is no name.
  final String identifier;

  /// Destination of the visit, falling back to its purpose.
  final String location;

  final String timestamp;

  final String iconPath;

  /// Source entity, used to open the detail screen.
  final GuestItemEntity? guest;
}

/// The newest [maxItems] guests by `guestDt` (descending), split into carousel
/// pages of [perPage] rows.
List<List<RecentGuestItem>> buildRecentGuestPages(
  List<GuestItemEntity> guests, {
  int maxItems = 12,
  int perPage = 3,
}) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final sorted = [...guests]
    ..sort(
      (a, b) => (AppDateFormat.tryParse(b.guestDt) ?? epoch).compareTo(
        AppDateFormat.tryParse(a.guestDt) ?? epoch,
      ),
    );
  final items = sorted
      .take(maxItems)
      .map(RecentGuestItem.fromGuest)
      .toList(growable: false);
  return [
    for (var i = 0; i < items.length; i += perPage)
      items.sublist(i, (i + perPage).clamp(0, items.length)),
  ];
}

/// Komponen kartu "Tamu Terakhir" dengan carousel multi-halaman
/// dan indikator titik. Murni presentasional: data dan status disuplai
/// pemanggil.
class HomeRecentGuestsCard extends StatefulWidget {
  const HomeRecentGuestsCard({
    super.key,
    this.guestPages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isFromCache = false,
    this.onRetry,
    this.onTapItem,
  });

  final List<List<RecentGuestItem>> guestPages;

  /// Shows skeleton rows instead of [guestPages].
  final bool isLoading;

  /// Shows an error with a retry button when there is nothing to display.
  final String? errorMessage;

  /// Marks the shown data as a saved (offline) copy.
  final bool isFromCache;

  final VoidCallback? onRetry;

  final void Function(RecentGuestItem item)? onTapItem;

  @override
  State<HomeRecentGuestsCard> createState() => _HomeRecentGuestsCardState();
}

class _HomeRecentGuestsCardState extends State<HomeRecentGuestsCard> {
  late final PageController _pageController;
  int _currentPage = 0;

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

  Widget _buildBody(BuildContext context) {
    final pages = widget.guestPages;
    if (widget.isLoading) return const _GuestRowsSkeleton();
    if (pages.isNotEmpty) {
      return PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: pages.length,
        itemBuilder: (context, pageIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space200,
              vertical: AppSpacing.space100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final item in pages[pageIndex])
                  _GuestRowItem(
                    item: item,
                    onTap: widget.onTapItem == null
                        ? null
                        : () => widget.onTapItem!(item),
                  ),
              ],
            ),
          );
        },
      );
    }
    return _GuestMessage(
      message: widget.errorMessage ?? 'Belum ada data tamu.',
      onRetry: widget.errorMessage == null ? null : widget.onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final pageCount = widget.isLoading ? 0 : widget.guestPages.length;

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
                      if (widget.isFromCache && !widget.isLoading)
                        Text(
                          'Data tersimpan',
                          style: typeScale.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                SizedBox(height: 168, child: _buildBody(context)),
              ],
            ),
          ),
        ),

        if (pageCount > 1) ...[
          AppSpacing.vGap150,

          // ── Dot Page Indicator ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              final isSelected = index == _currentPage.clamp(0, pageCount - 1);
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
      ],
    );
  }
}

/// Empty or error message inside the card body.
class _GuestMessage extends StatelessWidget {
  const _GuestMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.paddingHorizontalLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typeScale.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              AppSpacing.vGapSm,
              AppButton(
                style: AppButtonColor.tonal,
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Static placeholder rows (no fake data) shown while the first load runs.
class _GuestRowsSkeleton extends StatelessWidget {
  const _GuestRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).colorScheme.surfaceContainerHighest;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderFull,
      ),
    );

    return Semantics(
      label: 'Memuat tamu terakhir',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 3; i++)
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(120, 12),
                          AppSpacing.vGapXs,
                          bar(200, 10),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
        'Tamu ${item.identifier}, tujuan ${item.location}, '
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
