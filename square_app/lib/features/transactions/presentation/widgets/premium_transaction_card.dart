import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/transaction_row.dart';

enum TransactionType { expense, income, investment, loan }

/// Row for the mixed transactions feed (dashboard "recent" list, the
/// Transactions tab). Rebuilt on [TransactionRow] for consistent chrome;
/// type is now conveyed by icon + a neutral badge rather than a rainbow of
/// per-type colors.
class PremiumTransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;
  final bool isPositive;
  final VoidCallback? onTap;

  const PremiumTransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    this.isPositive = false,
    this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case TransactionType.expense:
        return Icons.receipt_long_outlined;
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.investment:
        return Icons.bar_chart;
      case TransactionType.loan:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final amountColor = isPositive
        ? AppColors.positive
        : (type == TransactionType.expense ? AppColors.negative : ink);

    final metaParts = <String>[
      _formatDate(date),
      if (category != null && category!.isNotEmpty) category!,
    ];

    return TransactionRow(
      icon: _icon,
      accentColor: ink,
      title: title,
      metaParts: metaParts,
      onTap: onTap,
      trailing: TransactionTrailing(
        secondary: subtitle.toUpperCase(),
        primary: Text(
          '${isPositive ? '+' : '−'}₹${_formatAmount(amount)}',
          style: AppTypography.amountInline.copyWith(color: amountColor),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.year == d.year) return DateFormat('MMM d').format(d);
    return DateFormat('MMM d, y').format(d);
  }

  String _formatAmount(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
