import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';

sealed class ForecastState extends Equatable {
  const ForecastState();

  @override
  List<Object?> get props => const [];
}

/// Loading the shifts and members of the group.
final class ForecastLoading extends ForecastState {
  const ForecastLoading();
}

final class ForecastLoadError extends ForecastState {
  const ForecastLoadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Every state after the options are loaded keeps them, plus the form values,
/// so going back to the configuration never loses input.
sealed class ForecastReady extends ForecastState {
  const ForecastReady({required this.options, required this.config});

  final ForecastOptions options;
  final ForecastConfig config;

  @override
  List<Object?> get props => [options, config];
}

/// Step 1. [showErrors] turns on the inline validation messages after a
/// failed attempt to preview; [error] is a failure of the preview request.
final class ForecastConfiguring extends ForecastReady {
  const ForecastConfiguring({
    required super.options,
    required super.config,
    this.showErrors = false,
    this.error,
  });

  final bool showErrors;
  final String? error;

  @override
  List<Object?> get props => [...super.props, showErrors, error];
}

final class ForecastPreviewLoading extends ForecastReady {
  const ForecastPreviewLoading({required super.options, required super.config});
}

/// Step 2. [applying] covers the commit request; [error] is a failure of the
/// last reshuffle or commit that left this preview usable.
final class ForecastPreviewReady extends ForecastReady {
  const ForecastPreviewReady({
    required super.options,
    required super.config,
    required this.preview,
    this.applying = false,
    this.error,
  });

  final ForecastPreview preview;
  final bool applying;
  final String? error;

  @override
  List<Object?> get props => [...super.props, preview, applying, error];
}

/// The commit was refused with 409: the data changed after the preview, so a
/// new preview is required. Nothing was saved.
final class ForecastStale extends ForecastReady {
  const ForecastStale({
    required super.options,
    required super.config,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}

final class ForecastApplied extends ForecastReady {
  const ForecastApplied({
    required super.options,
    required super.config,
    required this.preview,
    required this.result,
  });

  final ForecastPreview preview;
  final ForecastResult result;

  @override
  List<Object?> get props => [...super.props, preview, result];
}
