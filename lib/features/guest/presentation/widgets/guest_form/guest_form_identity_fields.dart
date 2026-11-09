import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/app_form_chip_group.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';

class GuestFormIdentityFields extends StatelessWidget {
  const GuestFormIdentityFields({
    required this.cubit,
    required this.identityNumberController,
    required this.identityNumberFocusNode,
    required this.addressFocusNode,
    super.key,
  });

  final GuestFormCubit cubit;
  final TextEditingController identityNumberController;
  final FocusNode identityNumberFocusNode;
  final FocusNode addressFocusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      GuestFormCubit,
      GuestFormState,
      ({
        String? identityType,
        String? identityNumberError,
        bool isBusy,
        int validationAttempt,
      })
    >(
      selector: (state) => (
        identityType: state.identityType,
        identityNumberError: state.identityNumberError,
        isBusy: state.isSubmitting,
        validationAttempt: state.validationAttempt,
      ),
      builder: (context, idState) {
        final hasIdentityType =
            idState.identityType != null && idState.identityType!.isNotEmpty;
        identityNumberFocusNode.canRequestFocus =
            hasIdentityType && !idState.isBusy;
        identityNumberFocusNode.skipTraversal =
            !hasIdentityType || idState.isBusy;

        final showError =
            idState.validationAttempt > 0 ||
            cubit.state.identityNumber.isNotEmpty;

        final chipItems = [
          AppFormChipItem<String?>(
            value: null,
            label: 'Tanpa Identitas',
            selected: idState.identityType == null,
          ),
          ...GuestIdentityType.values.map(
            (type) => AppFormChipItem<String?>(
              value: type.code,
              label: type.label,
              selected: idState.identityType == type.code,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormChipGroup<String?>(
              label: 'Jenis identitas',
              layout: AppFormChipGroupLayout.wrap,
              items: chipItems,
              selectedValue: idState.identityType,
              enabled: !idState.isBusy,
              onSelected: (val) {
                if (val == idState.identityType) return;
                cubit.onIdentityTypeChanged(val);
                if (val == null) {
                  identityNumberController.clear();
                } else {
                  identityNumberFocusNode.requestFocus();
                }
              },
            ),
            AppSpacing.vGap200,
            AppTextField(
              label: hasIdentityType
                  ? 'Nomor identitas (${idState.identityType}) *'
                  : 'Nomor identitas',
              variant: AppTextFieldVariant.outlined,
              controller: identityNumberController,
              focusNode: identityNumberFocusNode,
              enabled: !idState.isBusy && hasIdentityType,
              errorText: showError ? idState.identityNumberError : null,
              textInputAction: TextInputAction.next,
              onChanged: cubit.onIdentityNumberChanged,
              onSubmitted: (_) => addressFocusNode.requestFocus(),
            ),
          ],
        );
      },
    );
  }
}
