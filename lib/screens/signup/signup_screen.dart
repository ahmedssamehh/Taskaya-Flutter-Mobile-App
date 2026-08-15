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
import '../../widgets/google_signin_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _googleSubmitting = false;
  String? _authError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _authError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final error = await context.read<AuthProvider>().signup(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      setState(() => _authError = error);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(
        const HomeScreen(),
        settings: const RouteSettings(name: AppRoutes.home),
      ),
      (route) => false,
    );
  }

  Future<void> _submitGoogle() async {
    if (_googleSubmitting || _submitting) return;
    setState(() {
      _authError = null;
      _googleSubmitting = true;
    });
    final error = await context.read<AuthProvider>().loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleSubmitting = false);

    if (error != null) {
      setState(() => _authError = error);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(
        const HomeScreen(),
        settings: const RouteSettings(name: AppRoutes.home),
      ),
      (route) => false,
    );
  }

  void _goToLogin() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppMark(size: 64)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Create account',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'A few details and you are in',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      maxLength: Validators.maxNameLength,
                      style: AppTextStyles.body.copyWith(color: c.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        counterText: '',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: AppTextStyles.body.copyWith(color: c.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      style: AppTextStyles.body.copyWith(color: c.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: Validators.signupPassword,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'At least 8 characters, with a letter and a number',
                        style: AppTextStyles.meta.copyWith(
                          color: c.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.fieldGap),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: AppTextStyles.body.copyWith(color: c.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _authError == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.md),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 18, color: c.error),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _authError!,
                                      style: AppTextStyles.meta.copyWith(
                                        color: c.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Sign Up',
                      onPressed: _submit,
                      isLoading: _submitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: Divider(color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            'or',
                            style: AppTextStyles.meta.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: c.border)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GoogleSignInButton(
                      onPressed: _submitGoogle,
                      isLoading: _googleSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AppTextStyles.body.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        SecondaryButton(
                          label: 'Login',
                          onPressed: _goToLogin,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
