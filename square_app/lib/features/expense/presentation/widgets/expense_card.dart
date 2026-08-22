import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/transaction_row.dart';
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
    final description = expense.description;
    final amount = expense.amount;
    final date = expense.date;
    final category = expense.categoryName;
    final payerId = expense.payerId;
    final groupId = expense.groupId;

    final isPayer = payerId == currentUserId;
    final isPersonal = groupId == null;
    final isParticipant = expense.participants.contains(currentUserId);
    final isInvolved = isPayer || isParticipant;

    // Calculate personal share and involvement — unchanged business logic.
    double myShare = 0;
    if (expense.splits != null && expense.splits!.containsKey(currentUserId)) {
      myShare = expense.splits![currentUserId]!;
    } else if (isParticipant) {
      myShare = expense.amount / (expense.participants.length.toDouble());
    }

    double involvementAmount = 0;
    String involvementLabel = "";
    AmountSign sign = AmountSign.neutral;

    if (isPersonal) {
      involvementAmount = amount;
      involvementLabel = "Personal";
    } else if (!isInvolved) {
      involvementLabel = "Not involved";
    } else if (isPayer) {
      involvementAmount = amount - myShare;
      if (involvementAmount <= 0.01) {
        involvementLabel = "You paid for yourself";
      } else {
        involvementLabel = "You lent";
        sign = AmountSign.positive;
      }
    } else {
      involvementAmount = myShare;
      involvementLabel = "You owe";
      sign = AmountSign.negative;
    }

    String payerName = isPayer ? "You" : "Other";
    if (!isPayer && groupId != null) {
      final groupDetails = ref.watch(groupDetailsProvider(groupId)).value;
      if (groupDetails != null) {
        final member = groupDetails.members.where((m) => m.id == payerId).firstOrNull;
        if (member != null) payerName = member.shortName;
      }
    }

    final metaParts = <String>[
      DateFormat('MMM d').format(date),
      category,
      if (!isPersonal) (isPayer ? "You paid" : "$payerName paid"),
    ];

    return TransactionRow(
      icon: isPersonal ? Icons.receipt_long_outlined : Icons.people_outline,
      accentColor: AppColors.resolveCategoryColor(category, colorHex: expense.categoryColor),
      title: description,
      metaParts: metaParts,
      onTap: onTap,
      trailing: TransactionTrailing(
        secondary: !isPersonal ? 'Total ${_formatTotal(amount)}' : null,
        primary: (!isPersonal && !isInvolved)
            ? Text(involvementLabel, style: AppTypography.bodyMuted.copyWith(color: AppColors.inkFaint))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    amount: involvementAmount,
                    sign: sign,
                    showSignPrefix: false,
                    style: AppTypography.amountInline,
                  ),
                  if (involvementLabel != "Personal")
                    Text(
                      involvementLabel,
                      style: AppTypography.caption.copyWith(
                        color: sign == AmountSign.positive
                            ? AppColors.positive
                            : sign == AmountSign.negative
                                ? AppColors.negative
                                : AppColors.inkFaint,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _formatTotal(double v) => '₹${v.toStringAsFixed(0)}';
}
