import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddEntryBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Create New Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildOption(
                  context: context,
                  title: 'Expense',
                  subtitle: 'Add a new expense',
                  icon: LucideIcons.receipt,
                  color: Colors.red,
                  onTap: () {
                    context.pop();
                    context.push('/transactions/add-expense');
                  },
                ),
                _buildOption(
                  context: context,
                  title: 'Income',
                  subtitle: 'Add new income',
                  icon: LucideIcons.dollarSign,
                  color: Colors.green,
                  onTap: () {
                    context.pop();
                    context.push('/transactions/add-income');
                  },
                ),
                _buildOption(
                  context: context,
                  title: 'Investment',
                  subtitle: 'Add an investment',
                  icon: LucideIcons.trendingUp,
                  color: Colors.blue,
                  onTap: () {
                    context.pop();
                    context.push('/transactions/add-investment');
                  },
                ),
                _buildOption(
                  context: context,
                  title: 'Loan',
                  subtitle: 'Lent or borrowed money',
                  icon: LucideIcons.arrowLeftRight,
                  color: Colors.orange,
                  onTap: () {
                    context.pop();
                    context.push('/transactions/add-loan');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
        size: 16,
      ),
    );
  }
}
