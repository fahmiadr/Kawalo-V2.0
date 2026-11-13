import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_form_values.dart';

enum ShiftFormStatus { editing, saving, deleting }

class ShiftFormState extends Equatable {
  const ShiftFormState({
    required this.values,
    required this.initialValues,
    this.status = ShiftFormStatus.editing,
    this.showErrors = false,
    this.serverNameError,
  });

  final ShiftFormValues values;

  /// Baseline for [isDirty].
  final ShiftFormValues initialValues;
  final ShiftFormStatus status;

  /// Turned on by the first save attempt; from then on errors follow edits.
  final bool showErrors;

  /// Name conflict reported by the server; cleared by the next name edit.
  final String? serverNameError;

  bool get isBusy => status != ShiftFormStatus.editing;

  bool get isDirty => values != initialValues;

  ShiftFormErrors get errors {
    if (!showErrors) return ShiftFormErrors.none;
    final base = values.validate();
    final conflict = serverNameError;
    return conflict == null ? base : base.withName(conflict);
  }

  ShiftFormState copyWith({
    ShiftFormValues? values,
    ShiftFormStatus? status,
    bool? showErrors,
    String? Function()? serverNameError,
  }) => ShiftFormState(
    values: values ?? this.values,
    initialValues: initialValues,
    status: status ?? this.status,
    showErrors: showErrors ?? this.showErrors,
    serverNameError: serverNameError != null
        ? serverNameError()
        : this.serverNameError,
  );

  @override
  List<Object?> get props => [
    values,
    initialValues,
    status,
    showErrors,
    serverNameError,
  ];
}
