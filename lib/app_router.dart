import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_detail_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:kawalo_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Single place that decides where the user lands after an auth transition and
/// where deep links (push notifications) open.
///
/// It lives at the composition level, next to `main.dart`, because it knows
/// feature screens; `core/` must not import them. The navigator is resolved
/// lazily so the same class serves both callers:
///
/// * widgets: [AppRouter.of] uses the nearest [Navigator];
/// * code outside the tree (a notification handler): build it with the
///   `navigatorKey` given to the app, `AppRouter(() => key.currentState!)`.
class AppRouter {
  AppRouter(this._navigator);

  factory AppRouter.of(BuildContext context) =>
      AppRouter(() => Navigator.of(context));

  final NavigatorState Function() _navigator;

  /// Auth transitions clear the whole stack so back never returns to a screen
  /// that belongs to the previous session or to onboarding.
  Future<void> _resetTo(String name, WidgetBuilder builder) {
    return _navigator().pushAndRemoveUntil<void>(
      AppPageRoute.fade<void>(
        builder: builder,
        settings: RouteSettings(name: name),
      ),
      (route) => false,
    );
  }

  Future<void> toOnboarding() =>
      _resetTo(AppRouteNames.onboarding, (_) => const OnboardingScreen());

  Future<void> toLogin({String? sessionExpiredMessage}) => _resetTo(
    AppRouteNames.login,
    (_) => LoginScreen(sessionExpiredMessage: sessionExpiredMessage),
  );

  Future<void> toGroupSelection(UserEntity user) => _resetTo(
    AppRouteNames.groupSelection,
    (_) => GroupSelectionScreen(user: user),
  );

  /// Opens the group picker on top of the main shell so back cancels the
  /// switch; unlike [toGroupSelection] it does not clear the stack.
  Future<void> pushGroupSelection(UserEntity user) => _navigator().push<void>(
    AppPageRoute.forwardBackward<void>(
      builder: (_) => GroupSelectionScreen(user: user, allowCancel: true),
      settings: const RouteSettings(name: AppRouteNames.groupSelection),
    ),
  );

  Future<void> toMain() =>
      _resetTo(AppRouteNames.main, (_) => const MainNavigationScreen());

  /// Opens an incident thread on top of the current stack, e.g. from a push
  /// notification about a new reply. The caller must ensure a session exists.
  Future<void> openIncidentDetail(String incidentId) => _navigator().push<void>(
    IncidentDetailScreen.route(incidentId: incidentId),
  );
}
