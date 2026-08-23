import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/animated_background.dart';
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

  void _setMode(bool login) {
    if (login == isLogin) return;
    setState(() {
      isLogin = login;
      _formKey.currentState?.reset();
    });
  }

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
    final onInk = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark
        ? AppColors.surfaceRaisedDark
        : AppColors.surfaceSunken;

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
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(dotColor: ink)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand mark + wordmark
                  Column(
                    children: [
                      Image.asset(
                            'assets/images/square_logo.png',
                            width: 64,
                            height: 64,
                          )
                          .animate()
                          .scale(
                            delay: 150.ms,
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(delay: 150.ms, duration: 300.ms),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Square',
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Split expenses. Track every rupee.',
                        style: AppTypography.bodyMuted.copyWith(
                          color: inkMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Mode toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: sunken,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeOption(
                            label: 'Log in',
                            selected: isLogin,
                            ink: ink,
                            onInk: onInk,
                            inkMuted: inkMuted,
                            onTap: () => _setMode(true),
                          ),
                        ),
                        Expanded(
                          child: _ModeOption(
                            label: 'Sign up',
                            selected: !isLogin,
                            ink: ink,
                            onInk: onInk,
                            inkMuted: inkMuted,
                            onTap: () => _setMode(false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                              onPressed:
                                  () {}, // TODO: Implement forgot password
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
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  Row(
                    children: [
                      Expanded(
                        child: _FeatureHighlight(
                          icon: Icons.receipt_long_outlined,
                          label: 'Split bills',
                          ink: ink,
                          inkMuted: inkMuted,
                          sunken: sunken,
                        ),
                      ),
                      Expanded(
                        child: _FeatureHighlight(
                          icon: Icons.pie_chart_outline,
                          label: 'Track spend',
                          ink: ink,
                          inkMuted: inkMuted,
                          sunken: sunken,
                        ),
                      ),
                      Expanded(
                        child: _FeatureHighlight(
                          icon: Icons.trending_up_rounded,
                          label: 'See trends',
                          ink: ink,
                          inkMuted: inkMuted,
                          sunken: sunken,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 13, color: inkFaint),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Your data stays private and encrypted',
                        style: AppTypography.caption.copyWith(color: inkFaint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One pill of the Log in / Sign up segmented toggle.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.selected,
    required this.ink,
    required this.onInk,
    required this.inkMuted,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color ink;
  final Color onInk;
  final Color inkMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.button.copyWith(
              color: selected ? onInk : inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single "what this app does" chip shown below the form.
class _FeatureHighlight extends StatelessWidget {
  const _FeatureHighlight({
    required this.icon,
    required this.label,
    required this.ink,
    required this.inkMuted,
    required this.sunken,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final Color inkMuted;
  final Color sunken;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: sunken, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: inkMuted),
        ),
      ],
    );
  }
}

/// Faint dot-grid texture behind the hero — the "extra" visual detail that
/// keeps the page from reading as a bare form on an empty background.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.dotColor});

  final Color dotColor;

  static const double _spacing = 22;
  static const double _radius = 1.2;
  static const double _fadeHeight = 360;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    final height = _fadeHeight.clamp(0, size.height).toDouble();

    for (double y = 0; y < height; y += _spacing) {
      final fade = (1 - y / height).clamp(0.0, 1.0);
      paint.color = dotColor.withValues(alpha: 0.05 * fade);
      for (double x = 0; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}
