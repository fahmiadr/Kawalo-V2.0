import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Body of the preview call, and of the commit call once [seed] and
/// [previewToken] are set. Commit must send the same values as the preview:
/// the server recomputes the plan and compares the token.
class ForecastRequestModel {
  const ForecastRequestModel({
    required this.config,
    this.seed,
    this.previewToken,
    this.confirmOverwrite = false,
  });

  final ForecastConfig config;
  final int? seed;
  final String? previewToken;
  final bool confirmOverwrite;

  Map<String, dynamic> toJson() => {
    'start_date': _isoDate(config.startDate),
    'end_date': _isoDate(config.endDate),
    'shifts': [
      for (final e in config.quotas.entries)
        {'shift_uid': e.key, 'quota': e.value},
    ],
    'personnel': config.personnel,
    'fill_mode': config.fillMode.name,
    'rest_days': {
      'enabled': config.restEnabled,
      'max_consecutive': config.maxConsecutive,
    },
    'seed': ?seed,
    'preview_token': ?previewToken,
    if (previewToken != null) 'confirm_overwrite': confirmOverwrite,
  };
}
