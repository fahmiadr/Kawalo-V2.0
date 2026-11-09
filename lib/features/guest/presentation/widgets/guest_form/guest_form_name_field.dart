import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';

class GuestFormNameField extends StatelessWidget {
  const GuestFormNameField({
    required this.cubit,
    required this.controller,
    required this.focusNode,
    required this.identityNumberFocusNode,
    required this.addressFocusNode,
    super.key,
  });

  final GuestFormCubit cubit;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode identityNumberFocusNode;
  final FocusNode addressFocusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        GuestFormCubit,
        GuestFormState,
        ({
          String? error,
          bool enabled,
          bool hasIdentityType,
          int validationAttempt,
        })>(
      selector: (state) => (
        error: state.nameError,
        enabled: !state.isSubmitting,
        hasIdentityType: state.hasIdentityType,
        validationAttempt: state.validationAttempt,
      ),
      builder: (context, nameState) {
        final showError =
            nameState.validationAttempt > 0 || cubit.state.name.isNotEmpty;
        return AppTextField(
          label: 'Nama tamu',
          isRequired: true,
          variant: AppTextFieldVariant.outlined,
          controller: controller,
          focusNode: focusNode,
          enabled: nameState.enabled,
          errorText: showError ? nameState.error : null,
          textInputAction: TextInputAction.next,
          onChanged: cubit.onNameChanged,
          onSubmitted: (_) {
            if (nameState.hasIdentityType && nameState.enabled) {
              identityNumberFocusNode.requestFocus();
            } else {
              addressFocusNode.requestFocus();
            }
          },
        );
      },
    );
  }
}
