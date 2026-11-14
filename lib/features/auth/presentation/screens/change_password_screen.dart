import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/change_password_cubit.dart';

/// Changes the password of the signed-in user. Success invalidates every
/// session on the server, so the user is signed out and sent to the login
/// screen with a message.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const String successMessage =
      'Password berhasil diubah. Silakan masuk kembali.';

  static Route<void> route({
    required AuthRepository repository,
    required AuthBloc authBloc,
  }) => AppPageRoute.forwardBackward<void>(
    settings: const RouteSettings(name: AppRouteNames.changePassword),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ChangePasswordCubit(repository)),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: const ChangePasswordScreen(),
    ),
  );

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();

  // Set from the server's 403; cleared as soon as the user edits the field.
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _valid => ChangePasswordRules.isValid(
    current: _current.text,
    newValue: _new.text,
    repeatValue: _repeat.text,
  );

  void _onChanged({bool clearServerError = false}) => setState(() {
    if (clearServerError) _currentError = null;
  });

  void _submit() {
    if (!_valid) return;
    FocusScope.of(context).unfocus();
    unawaited(
      context.read<ChangePasswordCubit>().submit(
        currentPassword: _current.text,
        newPassword: _new.text,
      ),
    );
  }

  void _onState(BuildContext context, ChangePasswordState state) {
    switch (state.status) {
      case ChangePasswordStatus.wrongCurrent:
        setState(() => _currentError = state.message);
      case ChangePasswordStatus.failed:
        AppSnackbar.show(
          context,
          message: state.message ?? 'Gagal mengubah password.',
        );
      case ChangePasswordStatus.success:
        context.read<AuthBloc>().add(
          const LogoutRequested(message: ChangePasswordScreen.successMessage),
        );
      case ChangePasswordStatus.idle:
      case ChangePasswordStatus.saving:
        break;
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required String? errorText,
    required VoidCallback onChanged,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmitted,
    String? supportingText,
  }) => AppTextField(
    label: label,
    supportingText: supportingText,
    variant: AppTextFieldVariant.outlined,
    controller: controller,
    obscureText: true,
    showPasswordToggle: true,
    showPasswordSemanticsLabel: 'Tampilkan $label',
    hidePasswordSemanticsLabel: 'Sembunyikan $label',
    textInputAction: action,
    enabled: enabled,
    errorText: errorText,
    onChanged: (_) => onChanged(),
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
    leading: const AppSvgIcon(KawaloVectors.lockPassword),
  );

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listener: _onState,
      builder: (context, state) {
        final saving = state.status == ChangePasswordStatus.saving;
        final success = state.status == ChangePasswordStatus.success;
        return Scaffold(
          backgroundColor: tones.background,
          appBar: AppBar(
            backgroundColor: tones.background,
            scrolledUnderElevation: 0,
            title: const Text('Ganti Password'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.contentMaxWidth,
                        ),
                        child: Column(
                          children: [
                            _field(
                              label: 'Password lama',
                              controller: _current,
                              enabled: !saving,
                              errorText: _currentError,
                              onChanged: () =>
                                  _onChanged(clearServerError: true),
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'Password baru',
                              controller: _new,
                              enabled: !saving,
                              errorText: ChangePasswordRules.newPassword(
                                _new.text,
                                _current.text,
                              ),
                              supportingText: 'Minimal 8 karakter',
                              onChanged: _onChanged,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'Ulangi password baru',
                              controller: _repeat,
                              enabled: !saving,
                              errorText: ChangePasswordRules.repeat(
                                _repeat.text,
                                _new.text,
                              ),
                              onChanged: _onChanged,
                              action: TextInputAction.done,
                              onSubmitted: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: AppTaskButton(
                    label: 'Simpan Password',
                    isLoading: saving,
                    onPressed: _valid && !success ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
