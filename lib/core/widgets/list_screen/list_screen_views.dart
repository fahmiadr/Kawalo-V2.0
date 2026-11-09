import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

const _listPadding = EdgeInsets.only(
  left: AppSpacing.space200,
  right: AppSpacing.space200,
  top: AppSpacing.space150,
);

/// Scroll controller that calls [onLoadMore] once the user scrolls past 85% of
/// the extent.
class LoadMoreScrollController extends ScrollController {
  LoadMoreScrollController({required this.onLoadMore}) {
    addListener(_onScroll);
  }

  final VoidCallback onLoadMore;

  void _onScroll() {
    if (!hasClients) return;
    final maxScroll = position.maxScrollExtent;
    if (maxScroll > 0 && position.pixels >= maxScroll * 0.85) {
      onLoadMore();
    }
  }
}

/// Paginated list with a trailing loading indicator while [isLoadingMore].
///
/// [bottomPadding] defaults to the FAB clearance; pass a plain spacing for
/// screens without a FAB.
class ListScreenListView extends StatelessWidget {
  const ListScreenListView({
    required this.controller,
    required this.itemCount,
    required this.isLoadingMore,
    required this.itemBuilder,
    super.key,
    this.bottomPadding = AppLayout.fabScrollClearance,
  });

  final ScrollController controller;

  final int itemCount;

  final bool isLoadingMore;

  final IndexedWidgetBuilder itemBuilder;

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _listPadding.copyWith(bottom: bottomPadding),
      itemCount: itemCount + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => AppSpacing.vGap200,
      itemBuilder: (context, index) {
        if (index == itemCount) {
          return const Padding(
            padding: AppSpacing.paddingVertical200,
            child: Center(child: AppLoadingIndicator()),
          );
        }
        return itemBuilder(context, index);
      },
    );
  }
}

/// Non-scrollable placeholder list shown during the initial load; the feature
/// supplies its own skeleton card through [itemBuilder].
class ListScreenSkeleton extends StatelessWidget {
  const ListScreenSkeleton({
    required this.itemBuilder,
    super.key,
    this.bottomPadding = AppLayout.fabScrollClearance,
  });

  final IndexedWidgetBuilder itemBuilder;

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: _listPadding.copyWith(bottom: bottomPadding),
      itemCount: 4,
      separatorBuilder: (_, _) => AppSpacing.vGap200,
      itemBuilder: itemBuilder,
    );
  }
}

/// Empty result of a search or filter, with a reset action. [noun] is the
/// lower-case Indonesian name of the records, e.g. "data tamu".
class ListEmptySearchResult extends StatelessWidget {
  const ListEmptySearchResult({
    required this.noun,
    required this.onReset,
    super.key,
  });

  final String noun;

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.search(
      title: '${noun[0].toUpperCase()}${noun.substring(1)} tidak ditemukan',
      description:
          'Tidak ada $noun yang cocok dengan '
          'pencarian atau filter yang diterapkan.',
      actionLabel: 'Reset filter & pencarian',
      onActionPressed: onReset,
    );
  }
}

class ListErrorState extends StatelessWidget {
  const ListErrorState({
    required this.noun,
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String noun;

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.error(
      title: 'Gagal memuat $noun',
      description: message,
      retryLabel: 'Coba lagi',
      onRetry: onRetry,
    );
  }
}
