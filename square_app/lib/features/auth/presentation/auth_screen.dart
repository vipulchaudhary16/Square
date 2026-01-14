import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/glass_container.dart';
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

    // Listen for success
    ref.listen(authProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        context.go('/dashboard');
      }
      if (next.hasError) {
        print(next.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
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
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                width: double.infinity,
                // height: null, // Auto height
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary[500]!,
                              AppColors.primary[700]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary[500]!.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.lock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ).animate().scale(
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 16),

                      // Title & Subtitle
                      Text(
                        isLogin ? 'Welcome Back' : 'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : AppColors.slate[900],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin
                            ? 'Sign in to manage your expenses'
                            : 'Enter your details to get started',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.slate[400]
                              : AppColors.slate[500],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Signup additional fields
                      if (!isLogin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                label: 'First Name',
                                hint: 'John',
                                controller: _firstNameController,
                                prefixIcon: LucideIcons.user,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InputField(
                                label: 'Last Name',
                                hint: 'Doe',
                                controller: _lastNameController,
                                prefixIcon: LucideIcons.user,
                              ),
                            ),
                          ],
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),
                      ],

                      InputField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _emailController,
                        prefixIcon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      InputField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        prefixIcon: LucideIcons.lock,
                        isPassword: true,
                      ),

                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          controller: _confirmPasswordController,
                          prefixIcon: LucideIcons.lock,
                          isPassword: true,
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                      ],

                      if (isLogin) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {}, // TODO: Implement forgot password
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                      ],

                      PrimaryButton(
                        text: isLogin ? 'Sign In' : 'Create Account',
                        icon: LucideIcons.arrowRight,
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: 16),

                      // Toggle Mode
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.slate[400]
                                  : AppColors.slate[500],
                              fontSize: 14,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            children: [
                              TextSpan(
                                text: isLogin
                                    ? "Don't have an account? "
                                    : "Already have an account? ",
                              ),
                              TextSpan(
                                text: isLogin ? "Sign Up" : "Login",
                                style: TextStyle(
                                  color: AppColors.primary[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
