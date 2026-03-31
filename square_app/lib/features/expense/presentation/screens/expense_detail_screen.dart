import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../groups/presentation/groups_provider.dart';
import '../../data/expense_model.dart';
import '../expense_provider.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _isDeleting = false;

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await ref
            .read(expenseProvider.notifier)
            .deleteExpense(widget.expense.id);
        if (mounted) context.pop(); // Go back to list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authProvider).value;
    final isPayer = widget.expense.payerId == currentUser?.id;

    String payerName = isPayer ? "You" : "Other";
    if (!isPayer && widget.expense.groupId != null) {
      final groupDetails = ref.watch(groupDetailsProvider(widget.expense.groupId!)).value;
      if (groupDetails != null) {
        final member = groupDetails.members.where((m) => m.id == widget.expense.payerId).firstOrNull;
        if (member != null) {
          payerName = member.displayName;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit),
            color: isDark ? Colors.white : Colors.black,
            onPressed: () {
              context.push('/transactions/edit', extra: widget.expense);
            },
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.trash2),
            color: Colors.red,
            onPressed: _deleteExpense,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate[800] : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.receipt,
                    size: 48,
                    color: AppColors.primary[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.expense.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    color: isDark ? AppColors.slate[700] : AppColors.slate[200],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    context,
                    'Date',
                    DateFormat('MMM dd, yyyy').format(widget.expense.date),
                  ),
                  _buildDetailRow(context, 'Category', widget.expense.category),
                  _buildDetailRow(
                    context,
                    'Group',
                    widget.expense.groupName ?? 'Personal',
                  ),
                  _buildDetailRow(
                    context,
                    'Paid By',
                    payerName,
                  ),
                ],
              ),
            ),
            if (widget.expense.groupId != null) ...[
              const SizedBox(height: 24),
              _buildSplitBreakdown(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitBreakdown(BuildContext context, bool isDark) {
    final groupDetails = widget.expense.groupId != null
        ? ref.watch(groupDetailsProvider(widget.expense.groupId!)).value
        : null;

    final participants = widget.expense.participants;
    final splits = widget.expense.splits;
    final totalAmount = widget.expense.amount;
    final payerId = widget.expense.payerId;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 20,
                color: AppColors.primary[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Split Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.slate[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Group members and their shares
          if (groupDetails != null)
            ...groupDetails.members.map((member) {
              final isPayer = member.id == payerId;
              final isParticipant = participants.contains(member.id);
              if (!isPayer && !isParticipant) return const SizedBox.shrink();

              double share = 0;
              if (splits != null && splits.containsKey(member.id)) {
                share = splits[member.id]!;
              } else if (isParticipant) {
                share = totalAmount / participants.length.toDouble();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary[100],
                            child: Text(
                              member.displayName.isNotEmpty
                                  ? member.displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.shortName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.slate[900],
                                  ),
                                ),
                                if (isPayer)
                                  Text(
                                    'Paid the bill',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${share.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.slate[700],
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            const Center(
              child: Text('Loading split details...'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.slate[400] : AppColors.slate[500],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.slate[900],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
