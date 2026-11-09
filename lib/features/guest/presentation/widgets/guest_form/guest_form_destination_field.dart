import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';

class GuestFormDestinationField extends StatelessWidget {
  const GuestFormDestinationField({
    required this.cubit,
    required this.controller,
    required this.focusNode,
    super.key,
  });

  final GuestFormCubit cubit;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      GuestFormCubit,
      GuestFormState,
      ({String? error, bool enabled, int validationAttempt})
    >(
      selector: (state) => (
        error: state.destinationError,
        enabled: !state.isSubmitting,
        validationAttempt: state.validationAttempt,
      ),
      builder: (context, destState) {
        final showError =
            destState.validationAttempt > 0 ||
            cubit.state.destination.isNotEmpty;
        return AppTextField(
          label: 'Destinasi tujuan *',
          variant: AppTextFieldVariant.outlined,
          controller: controller,
          focusNode: focusNode,
          enabled: destState.enabled,
          errorText: showError ? destState.error : null,
          textInputAction: TextInputAction.done,
          onChanged: cubit.onDestinationChanged,
          onSubmitted: (_) {
            if (destState.enabled) {
              cubit.submit();
            }
          },
        );
      },
    );
  }
}
