import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';

/// Online-only: forecasting has no offline cache.
abstract interface class ForecastRepository {
  Future<Either<Failure, ForecastOptions>> loadOptions();

  /// Without [seed] the server picks one and returns it in the preview.
  Future<Either<Failure, ForecastPreview>> preview(
    ForecastConfig config, {
    int? seed,
  });

  /// A 409 failure means the data changed since [preview] was made.
  Future<Either<Failure, ForecastResult>> apply(
    ForecastConfig config, {
    required ForecastPreview preview,
    required bool confirmOverwrite,
  });
}
