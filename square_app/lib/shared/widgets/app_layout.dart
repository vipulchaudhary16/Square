import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AppLayout({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < 768; // Simple breakpoint

    return Scaffold(
      extendBody: false, // Content sits above nav

      body: Stack(
        children: [
          // Background Blobs (Global for layout)
          // If we want specific blobs per page, we can removing them here.
          // But React layout had them fixed.
          // However, AuthScreen has its own. Let's assume Main Layout also needs them.
          // I'll skip re-implementing them here to avoid clash or overhead,
          // or I can wrap `child` with a Stack if needed.
          // For now, let's just render child.
          child,
        ],
      ),
      bottomNavigationBar: isMobile ? _buildMobileNav(context) : null,
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = state.uri.path;

    return Container(
      height: 70, // Fixed height
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate[900] // Solid background for docked
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5), // Shadow upwards
          ),
        ],
      ),
      child: SafeArea(
        // Ensure nav items are safe from bottom edge on iOS
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.layoutGrid,
              label: 'Home',
              isSelected: currentPath == '/dashboard',
              onTap: () => context.go('/dashboard'),
            ),
            _NavItem(
              icon: LucideIcons.receipt,
              label: 'Transactions',
              isSelected: currentPath == '/transactions',
              onTap: () => context.go('/transactions'),
            ), // Placeholder path
            _NavItem(
              icon: LucideIcons.plus,
              label: 'Add',
              isPrimary: true,
              onTap: () => context.push('/expenses/add'),
            ),
            _NavItem(
              icon: LucideIcons.users,
              label: 'Groups',
              isSelected: currentPath.startsWith('/groups'),
              onTap: () => context.go('/groups'),
            ),
            _NavItem(
              icon: LucideIcons.user,
              label: 'Profile',
              isSelected: currentPath == '/profile',
              onTap: () => context.go('/profile'),
            ),
          ],
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
    if (isPrimary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary[600]!, AppColors.primary[500]!],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary[600]!.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? AppColors.primary[400] : AppColors.primary[600])
        : (isDark ? AppColors.slate[500] : AppColors.slate[400]);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
