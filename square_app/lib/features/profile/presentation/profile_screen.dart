import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/buttons/button_shell.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../auth/presentation/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
              child: Center(
                child: Text(
                  user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : 'U',
                  style: AppTypography.displayAmount.copyWith(
                    color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              user != null ? '${user.firstName} ${user.lastName}' : 'User',
              style: AppTypography.screenTitle.copyWith(color: ink),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(user?.email ?? 'No email', style: AppTypography.body.copyWith(color: inkMuted)),
            const SizedBox(height: AppSpacing.xxl),

            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  _ProfileOption(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    enabled: false,
                  ),
                  _ProfileOption(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    enabled: false,
                  ),
                  _ProfileOption(
                    icon: Icons.add_circle_outline,
                    title: 'Features',
                    onTap: () => context.push('/profile/features'),
                  ),
                  _ProfileOption(
                    icon: Icons.label_outline,
                    title: 'Categories',
                    onTap: () => context.push('/profile/categories'),
                  ),
                  _ProfileOption(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    enabled: false,
                  ),
                  _ProfileOption(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    enabled: false,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            SecondaryButton(
              text: 'Log out',
              icon: Icons.logout,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/auth');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    this.onTap,
    this.enabled = true,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final fg = enabled ? ink : inkFaint;

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: line)),
      ),
      child: ButtonShell(
        onTap: enabled ? onTap : null,
        borderRadius: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: AppTypography.body.copyWith(color: fg, fontWeight: FontWeight.w600)),
              ),
              if (enabled)
                Icon(Icons.chevron_right, size: 18, color: inkFaint)
              else
                Text('Soon', style: AppTypography.caption.copyWith(color: inkFaint)),
            ],
          ),
        ),
      ),
    );
  }
}
