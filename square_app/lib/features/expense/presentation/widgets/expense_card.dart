import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String currentUserId;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Handling potential missing fields safely
    final description = expense.description;
    final amount = expense.amount;
    final date = expense.date;
    final category = expense.category;
    final payerId = expense.payerId;
    final groupName = expense.groupName;
    final groupId = expense.groupId;

    final isPayer = payerId == currentUserId;
    final isPersonal = groupId == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.slate[700]! : AppColors.slate[100]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPersonal
                    ? (isDark
                          ? const Color(0xFF064e3b).withOpacity(0.4)
                          : const Color(0xFFecfdf5)) // Emerald
                    : (isDark
                          ? AppColors.primary[900]!.withOpacity(0.2)
                          : AppColors.primary[50]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  description.isNotEmpty ? description[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPersonal
                        ? (isDark
                              ? const Color(0xFF34d399)
                              : const Color(0xFF059669))
                        : (isDark
                              ? AppColors.primary[400]
                              : AppColors.primary[600]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM d').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.slate[400]
                              : AppColors.slate[500],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '•',
                          style: TextStyle(color: AppColors.slate[400]),
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.slate[400]
                              : AppColors.slate[500],
                        ),
                      ),
                      if (!isPersonal) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '•',
                            style: TextStyle(color: AppColors.slate[400]),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary[900]!.withOpacity(0.2)
                                : AppColors.primary[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            groupName ?? 'Group',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primary[400]
                                  : AppColors.primary[600],
                            ),
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
                  '${isPayer ? "+" : "-"} ₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPayer
                        ? (isDark
                              ? const Color(0xFF34d399)
                              : const Color(0xFF059669))
                        : (isDark
                              ? const Color(0xFFfb7185)
                              : const Color(0xFFf43f5e)), // Rose
                  ),
                ),
                Text(
                  isPayer ? "You paid" : "You owe",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.slate[500] : AppColors.slate[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
