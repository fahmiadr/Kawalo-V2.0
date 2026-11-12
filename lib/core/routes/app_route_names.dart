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
  static const String guestQrScan = '/guests/scan';
  static const String attendance = '/attendance';
  static const String schedule = '/schedule';
  static const String personnel = '/personnel';
  static const String information = '/information';
  static const String informationDetail = '/information/detail';
  static const String operational = '/operational';
  static const String operationalDetail = '/operational/detail';

  static const String incidents = '/incidents';
  static const String incidentCreate = '/incidents/create';
  static const String incidentDetail = '/incidents/detail';

  static const String shifts = '/shifts';
  static const String forecast = '/forecast';
  static const String forecastPersonnel = '/forecast/personnel';
  static const String scheduleAdmin = '/schedule/admin';
  static const String scheduleAdminDay = '/schedule/admin/day';
  static const String scheduleAdminForm = '/schedule/admin/form';
  static const String attendanceCheck = '/attendance/check';
  static const String attendanceManualRequests = '/attendance/manual-requests';
  static const String attendanceSettings = '/attendance/settings';
  static const String changePassword = '/settings/change-password';
  static const String faceData = '/faces';
  static const String faceRegistration = '/faces/register';

  static const String ptt = '/ptt';
  static const String pttHistory = '/ptt/history';
}
