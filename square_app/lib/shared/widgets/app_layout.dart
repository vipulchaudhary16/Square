import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_entry_bottom_sheet.dart';

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

      body: Stack(children: [child]),
      bottomNavigationBar: isMobile ? _buildMobileNav(context) : null,
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    final currentPath = state.uri.path;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5), // Shadow upwards
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                onTap: () => AddEntryBottomSheet.show(context),
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
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
        ),
      );
    }

    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
