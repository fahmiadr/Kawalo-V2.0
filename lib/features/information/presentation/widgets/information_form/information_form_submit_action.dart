import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';

/// Tombol aksi (Posting/Simpan) di bagian bawah dialog formulir informasi.
class InformationFormSubmitAction extends StatelessWidget {
  /// Membuat instance [InformationFormSubmitAction].
  const InformationFormSubmitAction({
    required this.cubit,
    required this.label,
    required this.session,
    super.key,
  });

  /// Cubit formulir yang menerima aksi kirim.
  final InformationFormCubit cubit;

  /// Label tombol.
  final String label;

  /// Sesi saat dialog dibuka, dipakai bila sesi aktif tidak tersedia.
  final AuthSessionEntity? session;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      InformationFormCubit,
      InformationFormState,
      ({bool canPress, bool isSubmitting})
    >(
      bloc: cubit,
      selector: (state) =>
          (canPress: state.canPressSubmit, isSubmitting: state.isSubmitting),
      builder: (actionContext, data) {
        return AppTaskButton(
          label: data.isSubmitting ? 'Menyimpan…' : label,
          icon: Icons.send_rounded,
          isLoading: data.isSubmitting,
          onPressed: data.canPress || data.isSubmitting
              ? () => cubit.submit(
                  session:
                      actionContext.read<UserSessionCubit?>()?.state ?? session,
                )
              : null,
        );
      },
    );
  }
}
