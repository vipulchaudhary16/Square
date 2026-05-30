import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.slate[900],
                ),
              ),
            ),
            const Divider(height: 24),
            _DrawerItem(
              icon: LucideIcons.layoutGrid,
              label: 'Dashboard',
              isSelected: currentPath == '/dashboard',
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            _DrawerItem(
              icon: LucideIcons.receipt,
              label: 'Transactions',
              isSelected: currentPath == '/transactions',
              onTap: () {
                Navigator.pop(context);
                context.go('/transactions');
              },
            ),
            _DrawerItem(
              icon: LucideIcons.users,
              label: 'Groups',
              isSelected: currentPath.startsWith('/groups'),
              onTap: () {
                Navigator.pop(context);
                context.go('/groups');
              },
            ),
            _DrawerItem(
              icon: LucideIcons.contact2,
              label: 'Contacts',
              isSelected: currentPath.startsWith('/contacts'),
              onTap: () {
                Navigator.pop(context);
                context.go('/contacts');
              },
            ),
            const Divider(height: 24),
            _DrawerItem(
              icon: LucideIcons.user,
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
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : (isDark ? AppColors.slate[300]! : AppColors.slate[600]!);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
