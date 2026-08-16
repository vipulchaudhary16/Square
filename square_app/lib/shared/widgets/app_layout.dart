import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/scaffold_key.dart';
import 'add_entry_bottom_sheet.dart';
import 'app_drawer.dart';
import 'buttons/button_shell.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AppLayout({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: appScaffoldKey,
      extendBody: false,
      endDrawer: const AppDrawer(),
      body: Stack(children: [child]),
      bottomNavigationBar: isMobile ? _buildMobileNav(context) : null,
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = state.uri.path;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_outlined,
                label: 'Home',
                isSelected: currentPath == '/dashboard',
                onTap: () => context.go('/dashboard'),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Transactions',
                isSelected: currentPath == '/transactions',
                onTap: () => context.go('/transactions'),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Add',
                isPrimary: true,
                onTap: () => AddEntryBottomSheet.show(context),
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'Groups',
                isSelected: currentPath.startsWith('/groups'),
                onTap: () => context.go('/groups'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: currentPath == '/profile',
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    if (isPrimary) {
      return ButtonShell(
        onTap: onTap,
        borderRadius: 24,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ink,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface, size: 22),
        ),
      );
    }

    final color = isSelected ? ink : inkFaint;

    return ButtonShell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
