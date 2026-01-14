import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

enum TransactionType { expense, income, investment, loan }

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

  Color get _typeColor {
    switch (type) {
      case TransactionType.expense:
        return const Color(0xFFef4444); // Red
      case TransactionType.income:
        return const Color(0xFF22c55e); // Green
      case TransactionType.investment:
        return const Color(0xFF8b5cf6); // Violet
      case TransactionType.loan:
        return const Color(0xFFf59e0b); // Amber
    }
  }

  IconData get _icon {
    switch (type) {
      case TransactionType.expense:
        return LucideIcons.receipt;
      case TransactionType.income:
        return LucideIcons.dollarSign;
      case TransactionType.investment:
        return LucideIcons.trendingUp;
      case TransactionType.loan:
        return LucideIcons.arrowLeftRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // Gradient Background for depth
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.cardDark, AppColors.surfaceDark]
                : [Colors.white, AppColors.slate[50]!],
          ),
          borderRadius: BorderRadius.circular(20),
          // Subtle colored border/glow
          border: Border.all(
            color: isDark ? typeColor.withOpacity(0.3) : AppColors.slate[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            // Subtle inner glow for dark mode
            if (isDark)
              BoxShadow(
                color: typeColor.withOpacity(0.05),
                blurRadius: 0,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: typeColor.withOpacity(0.3),
                    width: isDark ? 1 : 0,
                  ),
                ),
                child: Icon(_icon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM dd').format(date),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate[400]
                                : AppColors.slate[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (category != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.circle,
                              size: 4,
                              color: AppColors.slate[600],
                            ),
                          ),
                          Text(
                            category!,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.slate[400]
                                  : AppColors.slate[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isPositive
                          ? const Color(0xFF22c55e)
                          : (isDark ? Colors.white : AppColors.slate[900]),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate[800]
                          : AppColors.slate[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle, // "Lent" / "Details" etc
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate[300]
                            : AppColors.slate[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
