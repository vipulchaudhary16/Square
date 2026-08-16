import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/ghost_button.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!isLogin &&
          _passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      if (isLogin) {
        ref
            .read(authProvider.notifier)
            .login(_emailController.text, _passwordController.text);
      } else {
        ref
            .read(authProvider.notifier)
            .signup(
              _emailController.text,
              _passwordController.text,
              _firstNameController.text,
              _lastNameController.text,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;

    // Listen for success
    ref.listen(authProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        context.go('/dashboard');
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppCard(
                elevated: true,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mark
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
                          size: 26,
                        ),
                      ).animate().scale(
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Title & Subtitle
                      Text(
                        isLogin ? 'Welcome back' : 'Create account',
                        style: AppTypography.screenTitle.copyWith(color: ink),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isLogin
                            ? 'Sign in to manage your expenses'
                            : 'Enter your details to get started',
                        style: AppTypography.body.copyWith(color: inkMuted),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Signup additional fields
                      if (!isLogin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                label: 'First name',
                                hint: 'John',
                                controller: _firstNameController,
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: InputField(
                                label: 'Last name',
                                hint: 'Doe',
                                controller: _lastNameController,
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      InputField(
                        label: 'Email address',
                        hint: 'you@example.com',
                        controller: _emailController,
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      InputField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      if (!isLogin) ...[
                        const SizedBox(height: AppSpacing.md),
                        InputField(
                          label: 'Confirm password',
                          hint: '••••••••',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                      ],

                      if (isLogin) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: GhostButton(
                            text: 'Forgot password?',
                            compact: true,
                            onPressed: () {}, // TODO: Implement forgot password
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      const SizedBox(height: AppSpacing.xs),

                      PrimaryButton(
                        text: isLogin ? 'Sign in' : 'Create account',
                        icon: Icons.arrow_forward,
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Toggle mode
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isLogin = !isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodyMuted.copyWith(color: inkMuted),
                                children: [
                                  TextSpan(
                                    text: isLogin
                                        ? "Don't have an account? "
                                        : "Already have an account? ",
                                  ),
                                  TextSpan(
                                    text: isLogin ? "Sign up" : "Log in",
                                    style: AppTypography.bodyEmphasis.copyWith(color: ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
