import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/kawalo_logo.dart';

/// Custom Material 3 Expressive Home App Bar for Kawalo Mobile.
///
/// Features a two-tier header layout with optional search bar:
/// - Top tier: Greeting / update timestamp (e.g., "Selamat siang, admin..."
///   or "Diperbarui Hari ini, 15.20")
/// - Bottom tier: Horizontal row with optional back button, title / brand
///   logo, and an accessible [AppIconButton] with notification badge
/// - Optional [searchBar]: Slot for `AppSearchBar` placed directly beneath
///   the header tier.
class AppHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an [AppHomeAppBar].
  const AppHomeAppBar({
    this.greeting,
    super.key,
    this.title,
    this.unreadNotificationsCount = 0,
    this.onNotificationPressed,
    this.leading,
    this.trailing,
    this.reserveGreetingSpace = false,
    this.greetingLoading = false,
    this.showBackButton = false,
    this.showTrailing = true,
    this.onBackPressed,
    this.titleStyle,
    this.titleWidget,
    this.searchBar,
    this.searchBarPadding,
    this.searchBarHeight = defaultSearchBarHeight,
    this.bottom,
    this.backgroundColor,
    this.elevation = 0,
    this.padding,
    this.preferredHeight = defaultPreferredHeight,
    this.backButtonSize,
    this.leadingWidth,
    this.trailingWidth,
  });

  /// Default preferred height for [AppHomeAppBar] header tier (64dp).
  static const double defaultPreferredHeight = AppSpacing.space800;

  /// Default extra height added when [searchBar] is provided (76dp).
  static const double defaultSearchBarHeight = 76;

  /// Greeting or status text in the top tier (e.g. "Selamat siang, admin...").
  ///
  /// If omitted or empty, Tier 1 is skipped unless [reserveGreetingSpace] is
  /// true.
  final String? greeting;

  /// Whether to reserve vertical space for Tier 1 greeting/syncAt to prevent
  /// Cumulative Layout Shift (CLS) when sync timestamps load asynchronously.
  final bool reserveGreetingSpace;

  /// Whether the greeting/syncAt timestamp is actively loading.
  ///
  /// When true and [greeting] is empty, displays a shimmering pill placeholder
  /// without displaying false or misleading fallback timestamps.
  final bool greetingLoading;

  /// Whether to show the trailing action button or notification bell.
  ///
  /// Defaults to `true`. When set to `false`, no trailing button is rendered
  /// and content expands to the end padding.
  final bool showTrailing;

  /// Optional title text displayed in Tier 2 (e.g. "Data Tamu").
  ///
  /// If provided, renders an M3 Expressive title headline.
  /// If null and [leading] is null, defaults to [KawaloLogoText].
  final String? title;

  /// Number of unread notifications displayed inside the red badge.
  final int unreadNotificationsCount;

  /// Callback when the notification icon button is tapped.
  final VoidCallback? onNotificationPressed;

  /// Optional leading widget to replace or precede the brand logo.
  final Widget? leading;

  /// Optional trailing widget to override the default notification button.
  final Widget? trailing;

  /// Whether to show a back button before the title in Tier 2.
  final bool showBackButton;

  /// Callback when the back button is pressed.
  final VoidCallback? onBackPressed;

  /// Custom typography style for [title].
  final TextStyle? titleStyle;

  /// Optional custom title widget to replace or augment the default text title
  /// in Tier 2 (e.g. an inline dynamic search bar).
  final Widget? titleWidget;

  /// Optional search bar widget placed beneath the header tier.
  final Widget? searchBar;

  /// Custom padding around the [searchBar].
  final EdgeInsetsGeometry? searchBarPadding;

  /// Explicit height reserved for [searchBar] in [preferredSize].
  final double searchBarHeight;

  /// Optional bottom widget (e.g. [TabBar]).
  final PreferredSizeWidget? bottom;

  /// Background color of the app bar (default: `colorScheme.surface`).
  final Color? backgroundColor;

  /// Elevation of the app bar surface (default: 0).
  final double elevation;

  /// Custom inner padding for header tier.
  final EdgeInsetsGeometry? padding;

  /// Explicit height for the header tier (default: 64.0).
  final double preferredHeight;

  /// Optional size tier for the default back button
  /// (default: [AppIconButtonSize.sm]).
  final AppIconButtonSize? backButtonSize;

  /// Optional explicit width for [leading].
  final double? leadingWidth;

  /// Optional explicit width for [trailing].
  final double? trailingWidth;

  @override
  Size get preferredSize {
    var height = preferredHeight;
    if (searchBar != null) {
      height += searchBarHeight;
    }
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final effectiveBgColor = backgroundColor ?? colorScheme.surface;
    final effectivePadding =
        padding ??
        const EdgeInsets.only(
          left: AppSpacing.space200,
          right: AppSpacing.space200,
          top: AppSpacing.xs,
          bottom: AppSpacing.space150,
        );

    final effectiveSearchBarPadding =
        searchBarPadding ??
        const EdgeInsets.only(
          left: AppSpacing.space200,
          right: AppSpacing.space200,
          top: AppSpacing.space100,
          bottom: AppSpacing.space150,
        );

    final greetingStyle = typeScale.labelLarge.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final hasBack = showBackButton || onBackPressed != null;
    final hasLeadingButton =
        (leading != null && (title != null || titleWidget != null)) || hasBack;

    final resolvedPadding = effectivePadding.resolve(
      Directionality.of(context),
    );
    final headerHeight = preferredHeight;
    const rowHeight = AppSpacing.space300; // 24.0
    const targetSize = AppStateLayer.minTouchTarget; // 48.0

    final hasGreeting = greeting != null && greeting!.trim().isNotEmpty;
    final shouldReserveGreeting = reserveGreetingSpace || hasGreeting;

    // In M3 Expressive, the greeting label sits in Tier 1.
    // When greeting is present or space is reserved, Tier 2 (leading/title/
    // trailing row) is positioned with an explicit vertical separation below.
    const greetingHeight = 18.0;
    const greetingToRowGap = AppSpacing.sm; // 8.0dp
    final greetingBottom = resolvedPadding.top + greetingHeight;
    final rowTop = shouldReserveGreeting
        ? greetingBottom + greetingToRowGap
        : (headerHeight - rowHeight) / 2;
    final rowCenterY = rowTop + (rowHeight / 2);

    final effectiveLeadingWidth = leadingWidth ?? targetSize;
    final leadingPad = (effectiveLeadingWidth - rowHeight) / 2;
    final leadingActionLeft = resolvedPadding.left - leadingPad;

    final Widget? leadingActionWidget;
    if (leading != null && title != null) {
      leadingActionWidget = leading;
    } else if (hasBack) {
      leadingActionWidget = AppIconButton(
        size: backButtonSize ?? AppIconButtonSize.sm,
        icon: const AppSvgIcon(KawaloVectors.arrowLeft02, size: 28),
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        semanticLabel: 'Kembali',
      );
    } else {
      leadingActionWidget = null;
    }

    final effectiveTrailingWidth = trailingWidth ?? targetSize;
    final trailingButtonRight = resolvedPadding.right;

    final titleLeft = hasLeadingButton
        ? (leadingActionLeft + effectiveLeadingWidth + AppSpacing.sm).clamp(
            resolvedPadding.left + rowHeight + AppSpacing.sm,
            double.infinity,
          )
        : resolvedPadding.left;

    final contentRight = showTrailing
        ? trailingButtonRight + effectiveTrailingWidth + AppSpacing.sm
        : resolvedPadding.right;

    final Widget effectiveLeading;
    if (titleWidget != null) {
      effectiveLeading = titleWidget!;
    } else if (leading != null && title == null) {
      effectiveLeading = leading!;
    } else if (title != null) {
      effectiveLeading = Text(
        title!,
        style:
            titleStyle ??
            (hasLeadingButton
                ? emphasizedTypeScale.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  )
                : emphasizedTypeScale.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    leadingDistribution: TextLeadingDistribution.even,
                  )),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      effectiveLeading = const KawaloLogoText(textScaler: TextScaler.noScaling);
    }

    return Material(
      color: effectiveBgColor,
      elevation: elevation,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Tier 1: Subtitle / Greeting / Placeholder ─────
                  if (shouldReserveGreeting)
                    Positioned(
                      left: resolvedPadding.left,
                      top: resolvedPadding.top,
                      right: resolvedPadding.right + AppSpacing.space700,
                      child: SizedBox(
                        height: greetingHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: AppMotion.isReducedMotion(context)
                                ? Duration.zero
                                : AppDuration.short3,
                            switchInCurve: AppMotion.emphasizedDecelerate,
                            switchOutCurve: AppMotion.emphasizedAccelerate,
                            child: hasGreeting
                                ? Text(
                                    greeting!,
                                    key: ValueKey<String>('text_$greeting'),
                                    style: greetingStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : (greetingLoading
                                      ? const _GreetingSkeletonPill(
                                          key: ValueKey<String>('skeleton'),
                                        )
                                      : const SizedBox.shrink(
                                          key: ValueKey<String>('empty'),
                                        )),
                          ),
                        ),
                      ),
                    ),

                  // ── Tier 2: Title / Brand Logo ────────────────────
                  Positioned(
                    left: titleLeft,
                    right: contentRight,
                    top: rowCenterY,
                    child: FractionalTranslation(
                      translation: const Offset(0, -0.5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: AppMotion.isReducedMotion(context)
                              ? Duration.zero
                              : AppDuration.short3,
                          switchInCurve: AppMotion.emphasizedDecelerate,
                          switchOutCurve: AppMotion.emphasizedAccelerate,
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                alignment: Alignment.centerLeft,
                                children: [...previousChildren, ?currentChild],
                              ),
                          child: KeyedSubtree(
                            key: ValueKey<int>(titleWidget != null ? 1 : 0),
                            child: titleWidget != null
                                ? SizedBox(
                                    width: double.infinity,
                                    child: effectiveLeading,
                                  )
                                : effectiveLeading,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Trailing Action Button ────────────────────────
                  if (showTrailing)
                    Positioned(
                      right: trailingButtonRight,
                      top: rowCenterY,
                      child: FractionalTranslation(
                        translation: const Offset(0, -0.5),
                        child:
                            trailing ??
                            _NotificationActionButton(
                              unreadCount: unreadNotificationsCount,
                              onPressed: onNotificationPressed,
                            ),
                      ),
                    ),

                  // ── Leading Action Button (Back or Custom) ────────
                  if (hasLeadingButton && leadingActionWidget != null)
                    Positioned(
                      left: leadingActionLeft,
                      top: rowCenterY,
                      child: FractionalTranslation(
                        translation: const Offset(0, -0.5),
                        child: leadingActionWidget,
                      ),
                    ),
                ],
              ),
            ),
            if (searchBar != null)
              Padding(padding: effectiveSearchBarPadding, child: searchBar),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// Accessible notification action button using [AppIconButton] with badge.
class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);

    final semanticMessage = unreadCount > 0
        ? 'Notifikasi, $unreadCount pemberitahuan belum dibaca'
        : 'Notifikasi';

    final badgeValue = unreadCount > 0
        ? (unreadCount > 99 ? '99+' : unreadCount)
        : null;

    return AppIconButton(
      onPressed: onPressed,
      size: AppIconButtonSize.md,
      semanticLabel: semanticMessage,
      badgeValue: badgeValue,
      badgeColor: colorScheme.error,
      badgeTextColor: colorScheme.onError,
      icon: AppSvgIcon(
        KawaloVectors.notification01,
        size: 32,
        color: colorScheme.onSurface,
      ),
    );
  }
}

/// Shimmering skeleton pill for Tier 1 greeting/syncAt slot.
///
/// Prevents layout shift while fetching timestamps without displaying false
/// or misleading fallback dates.
class _GreetingSkeletonPill extends StatefulWidget {
  const _GreetingSkeletonPill({super.key});

  @override
  State<_GreetingSkeletonPill> createState() => _GreetingSkeletonPillState();
}

class _GreetingSkeletonPillState extends State<_GreetingSkeletonPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.extraLong4,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.isReducedMotion(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReduced = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHigh;
    final highlightColor = colorScheme.surfaceContainerHighest;

    return Semantics(
      label: 'Memuat status pembaruan data',
      child: isReduced
          ? Container(
              width: 112,
              height: 12,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: AppRadius.borderFull,
              ),
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final shimmerVal = _controller.value;
                return Container(
                  width: 112,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.borderFull,
                    gradient: LinearGradient(
                      colors: [baseColor, highlightColor, baseColor],
                      stops: const [0, 0.5, 1],
                      begin: Alignment(-2 + (shimmerVal * 4), 0),
                      end: Alignment(-1 + (shimmerVal * 4), 0),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
