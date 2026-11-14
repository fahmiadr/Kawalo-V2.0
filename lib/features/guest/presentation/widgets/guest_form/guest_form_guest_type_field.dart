import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/widgets/app_form_chip_group.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_master_field_states.dart';

class GuestFormGuestTypeField extends StatelessWidget {
  const GuestFormGuestTypeField({
    required this.cubit,
    required this.shimmerController,
    super.key,
  });

  final GuestFormCubit cubit;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      GuestFormCubit,
      GuestFormState,
      ({
        List<MasterGuestTypeEntity> masterTypes,
        bool isLoading,
        String? masterTypesError,
        String guestType,
        String? typeError,
        bool isBusy,
        int validationAttempt,
      })
    >(
      selector: (state) => (
        masterTypes: state.masterTypes,
        isLoading: state.isLoadingMasterTypes,
        masterTypesError: state.masterTypesError,
        guestType: state.guestType,
        typeError: state.typeError,
        isBusy: state.isSubmitting,
        validationAttempt: state.validationAttempt,
      ),
      builder: (context, typeState) {
        final showError =
            typeState.validationAttempt > 0 || typeState.guestType.isNotEmpty;

        Widget inputChild;
        if (typeState.isLoading) {
          inputChild = GuestFormDropdownSkeleton(
            shimmerController: shimmerController,
          );
        } else if (typeState.masterTypesError != null &&
            typeState.masterTypes.isEmpty) {
          inputChild = GuestFormMasterErrorWithRetry(
            message: 'Gagal memuat tipe tamu',
            tooltipMessage: 'Coba lagi memuat tipe tamu',
            onRetry: cubit.loadMasterGuestTypes,
          );
        } else {
          return AppFormChipGroup<String>(
            label: 'Tipe tamu',
            isRequired: true,
            layout: AppFormChipGroupLayout.wrap,
            items: [
              for (final type in typeState.masterTypes)
                AppFormChipItem<String>(value: type.name, label: type.name),
            ],
            selectedValue: typeState.guestType,
            enabled: !typeState.isBusy,
            onSelected: cubit.onGuestTypeChanged,
            errorText: showError ? typeState.typeError : null,
          );
        }

        return AppFormFieldSlot(
          label: 'Tipe tamu *',
          errorText: (showError && typeState.typeError != null)
              ? typeState.typeError
              : null,
          child: inputChild,
        );
      },
    );
  }
}
