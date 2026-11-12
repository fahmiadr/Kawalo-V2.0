import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_form_values.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_state.dart';

class ShiftFormCubit extends Cubit<ShiftFormState> {
  ShiftFormCubit({required this.repository, this.initial})
    : super(_initialState(initial));

  /// Radius chips offered next to "Lainnya", in metres.
  static const radiusPresets = [25, 50, 100, 200, 500, 1000];

  final ShiftRepository repository;

  /// The shift being edited, or `null` when creating.
  final ShiftEntity? initial;

  bool get isEdit => initial != null;

  static ShiftFormState _initialState(ShiftEntity? shift) {
    if (shift == null) {
      const values = ShiftFormValues();
      return const ShiftFormState(values: values, initialValues: values);
    }
    final radius = shift.radius;
    final values = ShiftFormValues(
      name: shift.name,
      startTime: shift.startTime,
      endTime: shift.endTime,
      // Purple legacy colours are not shown; saving falls back to the default.
      color: parseShiftColor(shift.color) == null
          ? ShiftFormValues.defaultColor
          : shift.color.toUpperCase(),
      description: shift.description ?? '',
      limitLocation: shift.hasLocation,
      latitude: shift.latitude,
      longitude: shift.longitude,
      locationName: shift.locationName ?? '',
      radiusText: '${radius ?? ShiftFormValues.defaultRadius}',
    );
    return ShiftFormState(
      values: values,
      initialValues: values,
      isCustomRadius: radius != null && !radiusPresets.contains(radius),
    );
  }

  void _update(ShiftFormValues values, {bool? isCustomRadius}) {
    if (isClosed) return;
    emit(state.copyWith(values: values, isCustomRadius: isCustomRadius));
  }

  void setName(String value) {
    if (isClosed) return;
    emit(
      state.copyWith(
        values: state.values.copyWith(name: value),
        serverNameError: () => null,
      ),
    );
  }

  void setStartTime(ShiftClock value) =>
      _update(state.values.copyWith(startTime: value));

  void setEndTime(ShiftClock value) =>
      _update(state.values.copyWith(endTime: value));

  void setColor(String hex) => _update(state.values.copyWith(color: hex));

  void setDescription(String value) =>
      _update(state.values.copyWith(description: value));

  // ignore: avoid_positional_boolean_parameters, used as a ValueChanged<bool>
  void setLimitLocation(bool value) =>
      _update(state.values.copyWith(limitLocation: value));

  void setCoordinates(double latitude, double longitude) =>
      _update(state.values.copyWith(latitude: latitude, longitude: longitude));

  void setLocationName(String value) =>
      _update(state.values.copyWith(locationName: value));

  void selectRadiusPreset(int metres) => _update(
    state.values.copyWith(radiusText: '$metres'),
    isCustomRadius: false,
  );

  void selectCustomRadius() => _update(state.values, isCustomRadius: true);

  void setRadiusText(String value) =>
      _update(state.values.copyWith(radiusText: value));

  /// `null` when the form is invalid (errors are then shown) or already busy.
  /// A name conflict (409) is reported on the name field; any other failure is
  /// returned for the screen to show.
  Future<Either<Failure, ShiftEntity>?> submit() async {
    if (state.isBusy || isClosed) return null;
    if (!state.values.validate().isValid) {
      emit(state.copyWith(showErrors: true));
      return null;
    }
    emit(state.copyWith(status: ShiftFormStatus.saving, showErrors: true));

    final input = state.values.toInput();
    final shift = initial;
    final result = shift == null
        ? await repository.createShift(input)
        : await repository.updateShift(shift.uid, input);
    if (isClosed) return result;

    final conflict = result.fold(
      (failure) => failure.statusCode == 409 ? failure.message : null,
      (_) => null,
    );
    emit(
      state.copyWith(
        status: ShiftFormStatus.editing,
        serverNameError: conflict == null ? null : () => conflict,
      ),
    );
    // A conflict is already shown on the field, so the screen has nothing more
    // to report.
    return conflict == null ? result : null;
  }

  /// Edit mode only; the screen reads a 409 (still used by schedules) from the
  /// failure.
  Future<Either<Failure, void>?> delete() async {
    final shift = initial;
    if (shift == null || state.isBusy || isClosed) return null;
    emit(state.copyWith(status: ShiftFormStatus.deleting));
    final result = await repository.deleteShift(shift.uid);
    if (!isClosed) emit(state.copyWith(status: ShiftFormStatus.editing));
    return result;
  }
}
