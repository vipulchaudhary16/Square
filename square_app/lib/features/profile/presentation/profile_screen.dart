import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 48), // Spacing for top
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary[400]!,
                          AppColors.primary[600]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary[500]!.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.firstName.isNotEmpty == true
                            ? user!.firstName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user != null ? '${user.firstName} ${user.lastName}' : 'User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No email',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.slate[400] : AppColors.slate[500],
              ),
            ),
            const SizedBox(height: 48),

            // Profile Options Section
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileOption(
                    context,
                    icon: LucideIcons.user,
                    title: 'Personal Information',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    context,
                    icon: LucideIcons.settings,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    context,
                    icon: LucideIcons.bell,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    context,
                    icon: LucideIcons.shield,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              text: 'Log Out',
              icon: LucideIcons.logOut,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/auth');
                }
              },
              // Make it look like a danger/secondary action? For now use PrimaryButton
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.slate[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : AppColors.slate[700],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.slate[800],
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 20,
        color: isDark ? AppColors.slate[600] : AppColors.slate[400],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
