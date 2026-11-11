import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';

class GuestFormHostField extends StatelessWidget {
  const GuestFormHostField({
    required this.cubit,
    required this.controller,
    required this.focusNode,
    required this.nextFocusNode,
    super.key,
  });

  final GuestFormCubit cubit;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      GuestFormCubit,
      GuestFormState,
      ({String? error, bool enabled})
    >(
      selector: (state) =>
          (error: state.hostNameError, enabled: !state.isSubmitting),
      builder: (context, hostState) {
        return AppTextField(
          label: 'Bertemu dengan (Tuan rumah)',
          placeholder: 'Nama tuan rumah',
          variant: AppTextFieldVariant.outlined,
          controller: controller,
          focusNode: focusNode,
          enabled: hostState.enabled,
          errorText: hostState.error,
          textInputAction: TextInputAction.next,
          onChanged: cubit.onHostNameChanged,
          onSubmitted: (_) => nextFocusNode.requestFocus(),
        );
      },
    );
  }
}
