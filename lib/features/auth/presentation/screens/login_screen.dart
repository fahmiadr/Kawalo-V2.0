import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_keyboard_auto_scroller.dart';
import 'package:kawalo_mobile/core/utils/app_validator.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/privacy_policy_bottom_sheet.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/terms_and_privacy_widget.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/terms_of_service_bottom_sheet.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';

/// Clean & Responsive Login Screen refactored from Figma specifications.
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.sessionExpiredMessage, super.key});

  /// Pesan opsional yang ditampilkan saat pengguna dialihkan ke login karena
  /// sesi kedaluwarsa atau anomali keamanan.
  final String? sessionExpiredMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final ScrollController _scrollController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final AppKeyboardAutoScroller _keyboardScroller;
  final GlobalKey _loginButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _scrollController = ScrollController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _keyboardScroller = AppKeyboardAutoScroller(
      scrollController: _scrollController,
    );
    _keyboardScroller.registerNodes([_emailFocusNode, _passwordFocusNode]);

    if (widget.sessionExpiredMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppSnackbar.show(context, message: widget.sessionExpiredMessage!);
        }
      });
    }

    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final storage = SecureStorageService();
      final savedEmail = await storage.getLastEmail();
      if (mounted && savedEmail != null && savedEmail.isNotEmpty) {
        if (_emailController.text.isEmpty) {
          setState(() {
            _emailController.text = savedEmail;
          });
        }
      }
    } on Object catch (_) {
      // Best-effort pre-fill email
    }
  }

  @override
  void dispose() {
    _keyboardScroller.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _emailError;
  String? _passwordError;

  void _validateInputs() {
    setState(() {
      _emailError = AppValidator.validateEmail(_emailController.text);
      _passwordError = AppValidator.validateLoginPassword(
        _passwordController.text,
      );
    });
  }

  void _onLoginSubmitted() {
    if (context.read<AuthBloc>().state is AuthLoading) return;

    _validateInputs();

    if (_emailError != null) {
      _emailFocusNode.requestFocus();
      _keyboardScroller.scrollToNode(_emailFocusNode, immediate: true);
      return;
    }

    if (_passwordError != null) {
      _passwordFocusNode.requestFocus();
      _keyboardScroller.scrollToNode(_passwordFocusNode, immediate: true);
      return;
    }

    // Dismiss keyboard before the loading state begins.
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthBloc>().add(
      LoginSubmitted(email: email, password: password),
    );
  }

  void _onForgotPasswordTap() {
    AppSnackbar.show(
      context,
      message: 'Fitur Lupa Password akan segera hadir.',
    );
  }

  @override
  Widget build(BuildContext context) {
    _keyboardScroller.attachContext(context);
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          AppSnackbar.show(context, message: state.message);
        } else if (state is Authenticated) {
          Navigator.of(context).pushAndRemoveUntil<void>(
            AppPageRoute.fade<void>(
              builder: (_) => const MainNavigationScreen(),
            ),
            (route) => false,
          );
        } else if (state is GroupSelectionRequired) {
          Navigator.of(context).pushAndRemoveUntil<void>(
            AppPageRoute.fade<void>(
              builder: (_) => GroupSelectionScreen(user: state.user),
            ),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return PopScope(
          canPop: !isLoading,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: colorScheme.surface,
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = AppLayout.isCompact(
                        constraints.maxWidth,
                      );
                      final horizontalPadding = AppLayout.horizontalMargin(
                        constraints.maxWidth,
                      );

                      Widget formContent = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isCompact) const Spacer(),

                          // 1. Header (Logo Responsif, Judul & Subjudul)
                          const AuthHeaderWidget(),

                          AppSpacing.vGap400,

                          // 2. Input Form (Email & Password)
                          _buildLoginForm(context, isLoading: isLoading),

                          AppSpacing.vGap300,

                          // 3. Terms & Privacy Consent Text
                          TermsAndPrivacyWidget(
                            onPrivacyTap: () =>
                                showPrivacyPolicyBottomSheet(context),
                            onTermsTap: () =>
                                showTermsOfServiceBottomSheet(context),
                          ),

                          if (isCompact) const Spacer(),

                          AppSpacing.vGap300,

                          // 4. Action Button (Masuk)
                          AppButton(
                            key: _loginButtonKey,
                            shape: AppButtonShape.square,
                            size: AppButtonSize.md,
                            enabled: !isLoading,
                            semanticLabel: isLoading
                                ? 'Memverifikasi akun'
                                : 'Masuk',
                            onPressed: isLoading ? null : _onLoginSubmitted,
                            child: Text('Masuk', style: typeScale.titleMedium),
                          ),
                        ],
                      );

                      if (!isCompact) {
                        formContent = AppCard(
                          variant: AppCardVariant.outlined,
                          padding: AppSpacing.paddingAllXl,
                          child: formContent,
                        );
                      }

                      return SingleChildScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: AppSpacing.space200,
                          bottom: AppSpacing.space200,
                        ),
                        child: AppScrollPadding(
                          revealTargetKey: _loginButtonKey,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: AppLayout.contentMaxWidth,
                                minHeight:
                                    constraints.maxHeight -
                                    (AppSpacing.space200 * 2),
                              ),
                              child: isCompact
                                  ? IntrinsicHeight(child: formContent)
                                  : formContent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Modal Scrim Overlay
              if (isLoading)
                const AppLoadingOverlay(semanticLabel: 'Memverifikasi akun'),
            ],
          ),
        );
      },
    );
  }

  /// Membangun form masukan email dan password dengan ikon SVG.
  /// [isLoading] mengunci seluruh field saat request async sedang berjalan
  /// sesuai M3 Disabled State — mencegah perubahan input yang sudah dikirim.
  Widget _buildLoginForm(BuildContext context, {required bool isLoading}) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input E-mail
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
            if (_emailError != null) {
              setState(() {
                _emailError = AppValidator.validateEmail(_emailController.text);
              });
            }
          },
          leading: const AppSvgIcon(KawaloVectors.mailAtSign01),
        ),

        AppSpacing.vGap200,

        // Input Password dengan tombol toggle password bawaan M3E
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

        AppSpacing.vGapXs,

        // Link Lupa Password (Compact Hyperlink)
        Align(
          alignment: Alignment.centerRight,
          child: AppTappable(
            onTap: _onForgotPasswordTap,
            semanticLabel: 'Lupa password?',
            child: Padding(
              padding: AppSpacing.paddingAllXs,
              child: Text(
                'Lupa password?',
                style: typeScale.labelLarge.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
