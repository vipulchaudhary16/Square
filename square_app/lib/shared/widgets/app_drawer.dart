import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
              child: Text('Menu', style: AppTypography.screenTitle.copyWith(color: ink)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Divider(height: AppSpacing.xl, color: isDark ? AppColors.lineDark : AppColors.line),
            ),
            _DrawerItem(
              icon: Icons.grid_view_outlined,
              label: 'Dashboard',
              isSelected: currentPath == '/dashboard',
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'Transactions',
              isSelected: currentPath == '/transactions',
              onTap: () {
                Navigator.pop(context);
                context.go('/transactions');
              },
            ),
            _DrawerItem(
              icon: Icons.people_outline,
              label: 'Groups',
              isSelected: currentPath.startsWith('/groups'),
              onTap: () {
                Navigator.pop(context);
                context.go('/groups');
              },
            ),
            _DrawerItem(
              icon: Icons.contact_page_outlined,
              label: 'Contacts',
              isSelected: currentPath.startsWith('/contacts'),
              onTap: () {
                Navigator.pop(context);
                context.go('/contacts');
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Divider(height: AppSpacing.xl, color: isDark ? AppColors.lineDark : AppColors.line),
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isSelected: currentPath == '/profile',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final color = isSelected ? ink : inkFaint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? sunken : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
