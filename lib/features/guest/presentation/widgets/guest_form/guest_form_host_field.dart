import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/app_dropdown_menu.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_form/guest_form_master_field_states.dart';

class GuestFormHostField extends StatelessWidget {
  const GuestFormHostField({
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
        List<GroupMemberEntity> masterHosts,
        bool isLoading,
        String? masterHostsError,
        String? hostEmail,
        bool isBusy,
      })
    >(
      selector: (state) => (
        masterHosts: state.masterHosts,
        isLoading: state.isLoadingMasterHosts,
        masterHostsError: state.masterHostsError,
        hostEmail: state.hostEmail,
        isBusy: state.isSubmitting,
      ),
      builder: (context, hostState) {
        Widget inputChild;
        if (hostState.isLoading) {
          inputChild = GuestFormDropdownSkeleton(
            shimmerController: shimmerController,
          );
        } else if (hostState.masterHostsError != null &&
            hostState.masterHosts.isEmpty) {
          inputChild = GuestFormMasterErrorWithRetry(
            message: 'Gagal memuat daftar warga',
            tooltipMessage: 'Coba lagi memuat daftar warga',
            onRetry: cubit.loadMasterHosts,
          );
        } else {
          inputChild = AppDropdownMenu<String>(
            items: hostState.masterHosts
                .map(
                  (host) => AppDropdownItem<String>(
                    value: host.email,
                    label: host.displayLabel,
                    selected: hostState.hostEmail == host.email,
                  ),
                )
                .toList(),
            singleSelect: true,
            searchEnabled: true,
            enabled: !hostState.isBusy,
            fieldStyle: const AppDropdownFieldStyle(
              hintText: 'Pilih tuan rumah',
              borderRadius: AppRadius.borderMedium,
            ),
            onSelectionChanged: (items) {
              cubit.onHostEmailChanged(
                items.isNotEmpty ? items.first.value : null,
              );
            },
          );
        }

        return AppFormFieldSlot(
          label: 'Bertemu dengan (Tuan rumah)',
          child: inputChild,
        );
      },
    );
  }
}
