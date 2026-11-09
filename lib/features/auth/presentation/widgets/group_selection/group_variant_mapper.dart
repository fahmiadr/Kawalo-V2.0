import 'package:kawalo_mobile/core/widgets/app_tag.dart';

AppTagVariant roleToVariant(String? category) {
  switch (category?.toUpperCase()) {
    case 'ADMIN':
      return AppTagVariant.primary;
    case 'GUARD':
      return AppTagVariant.secondary;
    case 'STAFF':
      return AppTagVariant.tertiary;
    case 'USER':
    default:
      return AppTagVariant.neutral;
  }
}

AppTagVariant groupStatusToVariant(String? status) {
  switch (status?.toUpperCase()) {
    case 'PAID':
      return AppTagVariant.primary;
    case 'CLIENT':
      return AppTagVariant.secondary;
    case 'TRIAL':
      return AppTagVariant.tertiary;
    default:
      return AppTagVariant.neutral;
  }
}
