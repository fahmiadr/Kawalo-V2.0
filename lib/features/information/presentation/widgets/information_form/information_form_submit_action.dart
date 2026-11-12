import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
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
    return BlocSelector<InformationFormCubit, InformationFormState, bool>(
      bloc: cubit,
      selector: (state) => state.canPressSubmit,
      builder: (actionContext, canPressSubmit) {
        return AppButton(
          size: AppButtonSize.md,
          enabled: canPressSubmit,
          onPressed: () {
            final activeSession =
                actionContext.read<UserSessionCubit?>()?.state ?? session;
            cubit.submit(session: activeSession);
          },
          child: Text(label),
        );
      },
    );
  }
}
