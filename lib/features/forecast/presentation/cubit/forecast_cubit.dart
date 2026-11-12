import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/repositories/forecast_repository.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';

class ForecastCubit extends Cubit<ForecastState> {
  ForecastCubit({
    required this.repository,
    DateTime Function() clock = DateTime.now,
    int Function()? newSeed,
  }) : _clock = clock,
       _newSeed = newSeed ?? _randomSeed,
       super(const ForecastLoading());

  /// The API accepts 0..=2147483647.
  static int _randomSeed() => Random().nextInt(0x7fffffff);

  /// Default range of the form: today and the six days after it.
  static const defaultRangeDays = 7;

  final ForecastRepository repository;
  final DateTime Function() _clock;
  final int Function() _newSeed;

  /// Drops answers of requests that were superseded (back, retry, close).
  int _requestId = 0;

  DateTime get today => ForecastConfig.dateOnly(_clock());

  Future<void> load() async {
    final id = ++_requestId;
    emit(const ForecastLoading());
    final result = await repository.loadOptions();
    if (id != _requestId || isClosed) return;
    result.fold(
      (failure) => emit(ForecastLoadError(failure.message)),
      (options) => emit(
        ForecastConfiguring(options: options, config: _initialConfig(options)),
      ),
    );
  }

  /// Every shift with quota 1 and the GUARD members selected (user decision:
  /// admins are scheduled only when ticked by hand).
  ForecastConfig _initialConfig(ForecastOptions options) {
    final start = today;
    return ForecastConfig(
      startDate: start,
      endDate: ForecastConfig.addDays(start, defaultRangeDays - 1),
      quotas: {for (final s in options.shifts) s.uid: 1},
      personnel: [
        for (final p in options.people)
          if (p.isGuard) p.email,
      ],
    );
  }

  void _edit(ForecastConfig Function(ForecastConfig config) change) {
    final current = state;
    if (current is! ForecastConfiguring) return;
    emit(
      ForecastConfiguring(
        options: current.options,
        config: change(current.config),
        showErrors: current.showErrors,
      ),
    );
  }

  void setRangeDays(int days) => _edit(
    (c) => c.copyWith(endDate: ForecastConfig.addDays(c.startDate, days - 1)),
  );

  /// Moving the start keeps the length of the range.
  void setStartDate(DateTime date) => _edit((c) {
    final start = ForecastConfig.dateOnly(date);
    return c.copyWith(
      startDate: start,
      endDate: ForecastConfig.addDays(start, c.rangeDays - 1),
    );
  });

  void setEndDate(DateTime date) =>
      _edit((c) => c.copyWith(endDate: ForecastConfig.dateOnly(date)));

  void toggleShift(String uid) => _edit((c) {
    final quotas = {...c.quotas};
    if (quotas.remove(uid) == null) quotas[uid] = 1;
    return c.copyWith(quotas: quotas);
  });

  void setQuota(String uid, int quota) => _edit((c) {
    if (!c.quotas.containsKey(uid)) return c;
    return c.copyWith(
      quotas: {...c.quotas, uid: quota.clamp(1, ForecastConfig.maxQuota)},
    );
  });

  void setPersonnel(List<String> emails) =>
      _edit((c) => c.copyWith(personnel: emails));

  void setRestEnabled({required bool enabled}) =>
      _edit((c) => c.copyWith(restEnabled: enabled));

  void setMaxConsecutive(int value) => _edit(
    (c) => c.copyWith(
      maxConsecutive: value.clamp(1, ForecastConfig.maxConsecutiveLimit),
    ),
  );

  void setFillMode(ForecastFillMode mode) =>
      _edit((c) => c.copyWith(fillMode: mode));

  /// "Lihat Pratinjau": validates, then asks the server for a plan.
  Future<void> requestPreview() async {
    final current = state;
    if (current is! ForecastConfiguring) return;
    if (!current.config.validate(today).isValid) {
      emit(
        ForecastConfiguring(
          options: current.options,
          config: current.config,
          showErrors: true,
        ),
      );
      return;
    }
    await _preview(
      current,
      onFailure: (message) => ForecastConfiguring(
        options: current.options,
        config: current.config,
        error: message,
      ),
    );
  }

  /// "Buat ulang": same form values, new seed. A failure keeps the plan that
  /// is already on screen.
  Future<void> reshuffle() async {
    final current = state;
    if (current is! ForecastPreviewReady || current.applying) return;
    await _preview(
      current,
      seed: _newSeed(),
      onFailure: (message) => ForecastPreviewReady(
        options: current.options,
        config: current.config,
        preview: current.preview,
        error: message,
      ),
    );
  }

  /// "Buat Pratinjau Ulang" after a 409.
  Future<void> retryPreview() async {
    final current = state;
    if (current is! ForecastStale) return;
    await _preview(
      current,
      onFailure: (message) => ForecastConfiguring(
        options: current.options,
        config: current.config,
        error: message,
      ),
    );
  }

  Future<void> _preview(
    ForecastReady from, {
    required ForecastState Function(String message) onFailure,
    int? seed,
  }) async {
    final id = ++_requestId;
    emit(ForecastPreviewLoading(options: from.options, config: from.config));
    final result = await repository.preview(from.config, seed: seed);
    if (id != _requestId || isClosed) return;
    result.fold(
      (failure) => emit(onFailure(failure.message)),
      (preview) => emit(
        ForecastPreviewReady(
          options: from.options,
          config: from.config,
          preview: preview,
        ),
      ),
    );
  }

  /// "Ubah Pengaturan": back to step 1 with the form values intact.
  void backToConfig() {
    final current = state;
    if (current is! ForecastReady || current is ForecastConfiguring) return;
    if (current is ForecastPreviewReady && current.applying) return;
    if (current is ForecastApplied) return;
    _requestId++;
    emit(ForecastConfiguring(options: current.options, config: current.config));
  }

  /// Saves the previewed plan. In overwrite mode the caller must have shown the
  /// confirmation (with the row count of the preview) and passes
  /// [overwriteConfirmed]; without it nothing is sent.
  Future<void> apply({bool overwriteConfirmed = false}) async {
    final current = state;
    if (current is! ForecastPreviewReady || current.applying) return;
    final overwrite = current.config.fillMode == ForecastFillMode.overwrite;
    if (overwrite && !overwriteConfirmed) return;

    final id = ++_requestId;
    emit(
      ForecastPreviewReady(
        options: current.options,
        config: current.config,
        preview: current.preview,
        applying: true,
      ),
    );
    final result = await repository.apply(
      current.config,
      preview: current.preview,
      confirmOverwrite: overwrite,
    );
    if (id != _requestId || isClosed) return;
    result.fold(
      (failure) => emit(
        failure.statusCode == 409
            ? ForecastStale(
                options: current.options,
                config: current.config,
                message: failure.message,
              )
            : ForecastPreviewReady(
                options: current.options,
                config: current.config,
                preview: current.preview,
                error: failure.message,
              ),
      ),
      (applied) => emit(
        ForecastApplied(
          options: current.options,
          config: current.config,
          preview: current.preview,
          result: applied,
        ),
      ),
    );
  }
}
