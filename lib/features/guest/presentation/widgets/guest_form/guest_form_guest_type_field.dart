import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/app_dropdown_menu.dart';
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
        })>(
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
          inputChild =
              GuestFormDropdownSkeleton(shimmerController: shimmerController);
        } else if (typeState.masterTypesError != null &&
            typeState.masterTypes.isEmpty) {
          inputChild = GuestFormMasterErrorWithRetry(
            message: 'Gagal memuat tipe tamu',
            tooltipMessage: 'Coba lagi memuat tipe tamu',
            onRetry: cubit.loadMasterGuestTypes,
          );
        } else {
          inputChild = AppDropdownMenu<String>(
            items: typeState.masterTypes
                .map(
                  (type) => AppDropdownItem<String>(
                    value: type.name,
                    label: type.name,
                    selected: typeState.guestType == type.name,
                  ),
                )
                .toList(),
            singleSelect: true,
            enabled: !typeState.isBusy,
            fieldStyle: const AppDropdownFieldStyle(
              hintText: 'Pilih tipe tamu',
              borderRadius: AppRadius.borderMedium,
            ),
            onSelectionChanged: (items) {
              cubit.onGuestTypeChanged(
                items.isNotEmpty ? items.first.value : '',
              );
            },
          );
        }

        return AppFormFieldSlot(
          label: 'Tipe tamu*',
          errorText: (showError && typeState.typeError != null)
              ? typeState.typeError
              : null,
          child: inputChild,
        );
      },
    );
  }
}
