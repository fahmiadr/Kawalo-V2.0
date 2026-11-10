/// Names attached to routes through `RouteSettings.name`.
///
/// The names identify screens for `AppRouteObserver` (and later analytics or
/// push-notification handling); they are not resolved by `onGenerateRoute`.
abstract final class AppRouteNames {
  const AppRouteNames._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String groupSelection = '/group-selection';
  static const String main = '/main';

  static const String guests = '/guests';
  static const String guestDetail = '/guests/detail';
  static const String attendance = '/attendance';
  static const String schedule = '/schedule';
  static const String information = '/information';
  static const String informationDetail = '/information/detail';
  static const String operational = '/operational';
  static const String operationalDetail = '/operational/detail';

  static const String incidents = '/incidents';
  static const String incidentCreate = '/incidents/create';
  static const String incidentDetail = '/incidents/detail';

  static const String ptt = '/ptt';
}
