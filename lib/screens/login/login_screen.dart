import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/routing/page_transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_mark.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../home/home_screen.dart';
import '../signup/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      _emailFocus.requestFocus();
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    Navigator.of(context).pushReplacement(
      fadeRoute(
        const HomeScreen(),
        settings: const RouteSettings(name: AppRoutes.home),
      ),
    );
  }

  void _goToSignup() {
    Navigator.of(context).push(
      slideRightRoute(
        const SignupScreen(),
        settings: const RouteSettings(name: AppRoutes.signup),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl - AppSpacing.md),
                AppMark(size: 32, color: c.accent),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Welcome back',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Log in to continue.',
                  style: AppTextStyles.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.error, width: 1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.controlRadius,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: c.error, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.meta.copyWith(
                              color: c.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                ],
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: null,
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PrimaryButton(
                  label: 'Log In',
                  onPressed: _submit,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: AppTextStyles.body.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    SecondaryButton(label: 'Sign Up', onPressed: _goToSignup),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
