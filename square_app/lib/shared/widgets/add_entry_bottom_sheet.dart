import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'buttons/button_shell.dart';

class AddEntryBottomSheet {
  static void show(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Create New Entry',
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EntryOption(
              title: 'Expense',
              subtitle: 'Add a new expense',
              icon: Icons.receipt_long_outlined,
              onTap: () {
                context.pop();
                context.pushReplacement('/transactions/add-expense');
              },
            ),
            _EntryOption(
              title: 'Income',
              subtitle: 'Add new income',
              icon: Icons.trending_up,
              onTap: () {
                context.pop();
                context.pushReplacement('/transactions/add-income');
              },
            ),
            _EntryOption(
              title: 'Investment',
              subtitle: 'Add an investment',
              icon: Icons.bar_chart,
              onTap: () {
                context.pop();
                context.pushReplacement('/transactions/add-investment');
              },
            ),
            _EntryOption(
              title: 'Loan',
              subtitle: 'Lent or borrowed money',
              icon: Icons.swap_horiz,
              onTap: () {
                context.pop();
                context.pushReplacement('/transactions/add-loan');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryOption extends StatelessWidget {
  const _EntryOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;

    return ButtonShell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: sunken, shape: BoxShape.circle),
              child: Icon(icon, color: ink, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardHeading.copyWith(color: ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: inkFaint),
          ],
        ),
      ),
    );
  }
}
