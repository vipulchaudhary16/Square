import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/expense_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../groups/presentation/groups_provider.dart';

class ExpenseCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final description = expense.description;
    final amount = expense.amount;
    final date = expense.date;
    final category = expense.category;
    final payerId = expense.payerId;
    final groupId = expense.groupId;

    final isPayer = payerId == currentUserId;
    final isPersonal = groupId == null;
    final isParticipant = expense.participants.contains(currentUserId);
    final isInvolved = isPayer || isParticipant;

    // Calculate personal share and involvement
    double myShare = 0;
    if (expense.splits != null && expense.splits!.containsKey(currentUserId)) {
      myShare = expense.splits![currentUserId]!;
    } else if (isParticipant) {
      myShare = expense.amount / (expense.participants.length.toDouble());
    }

    double involvementAmount = 0;
    String involvementLabel = "";
    Color involvementColor = Colors.grey;

    if (isPersonal) {
      involvementAmount = amount;
      involvementLabel = "Personal";
      involvementColor = isDark ? Colors.white : Colors.black87;
    } else if (!isInvolved) {
      involvementLabel = "Not involved";
      involvementColor = isDark ? Colors.white38 : Colors.black38;
    } else if (isPayer) {
      involvementAmount = amount - myShare;
      if (involvementAmount <= 0.01) {
        involvementLabel = "You paid for yourself";
        involvementColor = isDark ? Colors.white70 : Colors.black54;
      } else {
        involvementLabel = "You lent";
        involvementColor = Colors.green[400]!;
      }
    } else {
      involvementAmount = myShare;
      involvementLabel = "You owe";
      involvementColor = Colors.red[400]!;
    }

    String payerName = isPayer ? "You" : "Other";
    if (!isPayer && groupId != null) {
      final groupDetails = ref.watch(groupDetailsProvider(groupId)).value;
      if (groupDetails != null) {
        final member = groupDetails.members.where((m) => m.id == payerId).firstOrNull;
        if (member != null) {
          payerName = member.shortName;
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
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
                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  description.isNotEmpty ? description[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPersonal
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
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
                          overflow: TextOverflow.ellipsis,
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
                          Text(
                            isPayer ? "You paid" : "$payerName paid",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isPersonal && !isInvolved)
                  Text(
                    involvementLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: involvementColor,
                    ),
                  )
                else
                  Text(
                    '₹${involvementAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: involvementColor,
                    ),
                  ),
                if (involvementLabel != "Not involved" &&
                    involvementLabel != "Personal")
                  Text(
                    involvementLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: involvementColor.withOpacity(0.8),
                    ),
                  ),
                if (!isPersonal)
                  Text(
                    'Total ₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white24 : Colors.black26,
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
