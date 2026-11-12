import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_destructive_button.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_keyboard_insets_padding.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_selection_controller.dart';

/// Multi-select and batch-delete wiring of a [ListScreenScaffold].
///
/// While items are selected the scaffold shows a bottom "Hapus (N)" bar that
/// calls [onDelete]; the header keeps only close, count and select-all.
class ListScreenSelection {
  const ListScreenSelection({
    required this.controller,
    required this.itemCount,
    required this.onClear,
    required this.onAllSelected,
    required this.onDelete,
    required this.isDeleting,
    required this.deleteLabel,
    required this.deletingLabel,
    required this.deletingMessage,
  });

  final ListSelectionController controller;

  final int itemCount;

  final VoidCallback onClear;

  final ValueChanged<bool> onAllSelected;

  final VoidCallback onDelete;

  final bool isDeleting;

  final String deleteLabel;

  final String deletingLabel;

  final String deletingMessage;
}

/// Scaffold shared by the list screens: search-aware home app bar, optional
/// selection app bar, filter bar, pull-to-refresh body, create FAB and
/// offline handling.
///
/// Set [canPop] to false together with [onPopBlocked] to intercept back
/// navigation.
class ListScreenScaffold extends StatelessWidget {
  const ListScreenScaffold({
    required this.title,
    required this.searchLabel,
    required this.refreshLabel,
    required this.greeting,
    required this.isInitialLoading,
    required this.isOffline,
    required this.isSearchExpanded,
    required this.searchController,
    required this.onSearch,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onRefresh,
    required this.filterBar,
    required this.body,
    super.key,
    this.showBackButton = true,
    this.hasBottomNavigationBar = false,
    this.bottomNavigationBar,
    this.selection,
    this.createLabel,
    this.onCreate,
    this.canRefresh = true,
    this.canPop = true,
    this.onPopBlocked,
    this.trailingActions = const [],
  });

  final String title;

  /// Hint of the search field and semantic label of the search button.
  final String searchLabel;

  final String refreshLabel;

  final String greeting;

  final bool isInitialLoading;

  final bool isOffline;

  final bool isSearchExpanded;

  final TextEditingController searchController;

  final ValueChanged<String> onSearch;

  final VoidCallback onOpenSearch;

  final VoidCallback onCloseSearch;

  final Future<void> Function() onRefresh;

  final Widget filterBar;

  final Widget body;

  final bool showBackButton;

  final bool hasBottomNavigationBar;

  final Widget? bottomNavigationBar;

  final ListScreenSelection? selection;

  /// The create FAB is hidden when [onCreate] is null or while selecting.
  final String? createLabel;

  final VoidCallback? onCreate;

  /// Pull-to-refresh is always off while selecting.
  final bool canRefresh;

  final bool canPop;

  final VoidCallback? onPopBlocked;

  /// Icon buttons shown to the left of the search button in the idle app bar.
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final selection = this.selection;
    final isSelecting = selection?.controller.isSelectionMode ?? false;

    final searchButton = AppIconButton(
      onPressed: !isInitialLoading
          ? (isSearchExpanded ? onCloseSearch : onOpenSearch)
          : null,
      semanticLabel: isSearchExpanded ? 'Tutup pencarian' : searchLabel,
      icon: AppSvgIcon(
        isSearchExpanded ? KawaloVectors.cancel01 : KawaloVectors.search01,
        size: 24,
        color: !isInitialLoading
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(
                alpha: AppStateLayer.disabledOpacity,
              ),
      ),
    );

    final idleAppBar = AppHomeAppBar(
      greeting: greeting,
      reserveGreetingSpace: true,
      greetingLoading: isInitialLoading && greeting.isEmpty,
      title: isSearchExpanded ? null : title,
      titleWidget: isSearchExpanded
          ? AppSearchBar(
              controller: searchController,
              hintText: searchLabel,
              autoFocus: true,
              enabled: !isInitialLoading,
              onSearch: onSearch,
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
            )
          : null,
      showBackButton: showBackButton,
      trailing: trailingActions.isEmpty
          ? searchButton
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [...trailingActions, searchButton],
            ),
      trailingWidth: trailingActions.isEmpty
          ? null
          : AppStateLayer.minTouchTarget * (trailingActions.length + 1),
    );

    final canCreate = onCreate != null && !isSelecting;

    Widget result = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      floatingActionButtonLocation: const AppStationaryEndFloatFabLocation(),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      appBar: selection == null
          ? idleAppBar
          : AppSelectionAppBar(
              idle: idleAppBar,
              controller: selection.controller.controller,
              showSelectAll: true,
              itemCount: selection.itemCount,
              onClear: selection.onClear,
              onAllSelected: selection.onAllSelected,
            ),
      floatingActionButton: canCreate
          ? AppExtendedFab(
              onPressed: isOffline ? null : onCreate,
              icon: const AppSvgIcon(KawaloVectors.add01, size: 24),
              label: createLabel!,
            )
          : null,
      bottomNavigationBar: selection == null || !isSelecting
          ? bottomNavigationBar
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPageActions(
                  children: [
                    AppDestructiveButton(
                      label: 'Hapus (${selection.controller.selectedCount})',
                      semanticLabel: selection.deleteLabel,
                      enabled: !selection.isDeleting && !isOffline,
                      onPressed: selection.onDelete,
                    ),
                  ],
                ),
                ?bottomNavigationBar,
              ],
            ),
      body: SafeArea(
        top: false,
        child: AppKeyboardInsetsPadding(
          hasBottomNavigationBar: hasBottomNavigationBar,
          isOffline: isOffline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filterBar,
              Expanded(
                child: AppRefreshIndicator.contained(
                  semanticsLabel: refreshLabel,
                  notificationPredicate: canRefresh && !isSelecting
                      ? defaultScrollNotificationPredicate
                      : (_) => false,
                  onRefresh: onRefresh,
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selection != null) {
      result = AppLoadingOverlay(
        isLoading: selection.isDeleting,
        semanticLabel: selection.deletingLabel,
        message: selection.deletingMessage,
        child: result,
      );
    }

    if (onPopBlocked != null) {
      result = PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onPopBlocked!();
        },
        child: result,
      );
    }

    return result;
  }
}
