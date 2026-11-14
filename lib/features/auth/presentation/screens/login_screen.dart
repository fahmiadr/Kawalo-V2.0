import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_validator.dart';
import 'package:kawalo_mobile/core/widgets/app_inline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/saved_email_cubit.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/privacy_policy_bottom_sheet.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/terms_and_privacy_widget.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/terms_of_service_bottom_sheet.dart';

/// "Masuk" (redesign 2026): e-mail and password, the 64 px "Masuk" button
/// pinned above the keyboard. A wrong password is shown under the password
/// field; a lockout (429) and being offline get a banner above the form.
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.sessionExpiredMessage, super.key});

  /// Shown once as a snackbar when the user was sent here because the session
  /// expired or a security anomaly was detected.
  final String? sessionExpiredMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  late final SavedEmailCubit _savedEmailCubit;

  String? _emailError;
  String? _passwordError;

  /// Server message of a 429 (account locked or too many attempts).
  String? _lockedMessage;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpiredMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppSnackbar.show(context, message: widget.sessionExpiredMessage!);
        }
      });
    }
    _savedEmailCubit = SavedEmailCubit(context.read<SecureStorageService?>())
      ..load();
  }

  void _prefillEmail(String email) {
    if (_emailController.text.isEmpty) {
      setState(() => _emailController.text = email);
    }
  }

  @override
  void dispose() {
    unawaited(_savedEmailCubit.close());
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginSubmitted() {
    if (context.read<AuthBloc>().state is AuthLoading) return;

    setState(() {
      _emailError = AppValidator.validateEmail(_emailController.text);
      _passwordError = AppValidator.validateLoginPassword(
        _passwordController.text,
      );
      _lockedMessage = null;
    });
    if (_emailError != null) {
      _emailFocusNode.requestFocus();
      return;
    }
    if (_passwordError != null) {
      _passwordFocusNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  void _onAuthState(BuildContext context, AuthState state) {
    switch (state) {
      case AuthFailure(statusCode: 401, :final message):
        setState(() => _passwordError = message);
      case AuthFailure(statusCode: 429, :final message):
        setState(() => _lockedMessage = message);
      case AuthFailure(:final message):
        AppSnackbar.show(context, message: message);
      case Authenticated():
        unawaited(AppRouter.of(context).toMain());
      case GroupSelectionRequired(:final user):
        unawaited(AppRouter.of(context).toGroupSelection(user));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final connectivity = context.read<ConnectivityCubit?>();

    return BlocListener<SavedEmailCubit, String?>(
      bloc: _savedEmailCubit,
      listener: (_, email) {
        if (email != null) _prefillEmail(email);
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: _onAuthState,
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final isOffline =
              connectivity != null &&
              context.select<ConnectivityCubit, bool>((c) => c.isOffline);

          return PopScope(
            canPop: !isLoading,
            child: Scaffold(
              backgroundColor: tones.background,
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.contentMaxWidth,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                            child: _buildForm(
                              tones,
                              isLoading: isLoading,
                              isOffline: isOffline,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppTaskButton(
                                label: isLoading ? 'Memeriksa…' : 'Masuk',
                                isLoading: isLoading,
                                onPressed: isOffline ? null : _onLoginSubmitted,
                              ),
                              const SizedBox(height: 8),
                              TermsAndPrivacyWidget(
                                onPrivacyTap: () =>
                                    showPrivacyPolicyBottomSheet(context),
                                onTermsTap: () =>
                                    showTermsOfServiceBottomSheet(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    KawaloTones tones, {
    required bool isLoading,
    required bool isOffline,
  }) {
    final lockedMessage = _lockedMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tones.ptt.soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 28,
              color: tones.ptt.color,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            'Masuk',
            style: TextStyle(
              color: tones.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pakai akun Kawalo dari admin grup Anda.',
          style: TextStyle(color: tones.ink2, fontSize: 14),
        ),
        if (isOffline) ...[
          const SizedBox(height: 14),
          const AppInlineBanner(
            message: 'Tidak ada koneksi internet. Sambungkan dulu untuk masuk.',
          ),
        ] else if (lockedMessage != null) ...[
          const SizedBox(height: 14),
          AppInlineBanner(
            message: lockedMessage,
            icon: Icons.lock_outline_rounded,
            kind: AppInlineBannerKind.error,
          ),
        ],
        const SizedBox(height: 14),
        AppTextField(
          label: 'E-mail',
          variant: AppTextFieldVariant.outlined,
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          errorText: _emailError,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          onChanged: (_) {
            if (_emailError != null || _lockedMessage != null) {
              setState(() {
                _lockedMessage = null;
                if (_emailError != null) {
                  _emailError = AppValidator.validateEmail(
                    _emailController.text,
                  );
                }
              });
            }
          },
          leading: const AppSvgIcon(KawaloVectors.mailAtSign01),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Password',
          variant: AppTextFieldVariant.outlined,
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: true,
          showPasswordToggle: true,
          showPasswordSemanticsLabel: 'Tampilkan password',
          hidePasswordSemanticsLabel: 'Sembunyikan password',
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          errorText: _passwordError,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          onSubmitted: (_) => _onLoginSubmitted(),
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() {
                _passwordError = AppValidator.validateLoginPassword(
                  _passwordController.text,
                );
              });
            }
          },
          leading: const AppSvgIcon(KawaloVectors.lockPassword),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: AppTaskButton(
            label: 'Lupa password?',
            variant: AppTaskButtonVariant.secondary,
            size: AppTaskButtonSize.small,
            onPressed: () => unawaited(ForgotPasswordSheet.show(context)),
          ),
        ),
      ],
    );
  }
}
