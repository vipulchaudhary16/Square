import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../groups/presentation/groups_provider.dart';
import '../../data/expense_model.dart';
import '../expense_provider.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _isDeleting = false;

  Future<void> _deleteExpense() async {
    var confirmed = false;
    await AppDialog.show(
      context,
      title: 'Delete expense?',
      message: 'Are you sure you want to delete this expense? This action cannot be undone.',
      actions: [
        AppDialogAction(label: 'Cancel', onPressed: () {}),
        AppDialogAction(
          label: 'Delete',
          isDestructive: true,
          onPressed: () => confirmed = true,
        ),
      ],
    );

    if (confirmed) {
      setState(() => _isDeleting = true);
      try {
        await ref.read(expenseProvider.notifier).deleteExpense(widget.expenseId);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final currentUserId = ref.watch(authProvider).value?.id;
    final dataAsync = ref.watch(expenseDetailProvider(widget.expenseId));
    final expense = dataAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Details', style: AppTypography.screenTitle.copyWith(color: ink, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (expense != null) ...[
            AppIconButton(
              icon: Icons.edit,
              onPressed: () => context.push('/transactions/edit', extra: expense),
            ),
            const SizedBox(width: AppSpacing.xs),
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : AppIconButton(icon: Icons.delete_outline, onPressed: _deleteExpense),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(expenseDetailProvider(widget.expenseId)),
        ),
        data: (expense) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(expenseDetailProvider(widget.expenseId));
            await ref.read(expenseDetailProvider(widget.expenseId).future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  elevated: true,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.categoryAccent(expense.categoryName).withValues(alpha: isDark ? 0.18 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 24,
                          color: AppColors.categoryAccent(expense.categoryName),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        expense.description,
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionHeading.copyWith(color: ink),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AmountText(
                        amount: expense.amount,
                        style: AppTypography.displayAmount,
                        showSignPrefix: false,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Divider(color: isDark ? AppColors.lineDark : AppColors.line),
                      const SizedBox(height: AppSpacing.xl),
                      _buildDetailRow(context, 'Date', DateFormat('MMM dd, yyyy').format(expense.date)),
                      _buildDetailRow(context, 'Category', expense.categoryName),
                      _buildDetailRow(context, 'Group', expense.groupName ?? 'Personal'),
                      _buildDetailRow(
                        context,
                        'Paid By',
                        expense.payerId == currentUserId ? 'You' : (expense.payerName ?? 'Other'),
                      ),
                    ],
                  ),
                ),
                if (expense.groupId != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildSplitBreakdown(context, isDark, expense),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitBreakdown(BuildContext context, bool isDark, Expense expense) {
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final groupDetails = expense.groupId != null ? ref.watch(groupDetailsProvider(expense.groupId!)).value : null;

    final participants = expense.participants;
    final splits = expense.splits;
    final totalAmount = expense.amount;
    final payerId = expense.payerId;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: ink),
              const SizedBox(width: AppSpacing.sm),
              Text('Split Details', style: AppTypography.sectionHeading.copyWith(color: ink)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (groupDetails != null)
            ...groupDetails.members.map((member) {
              final isPayer = member.id == payerId;
              final isParticipant = participants.contains(member.id);
              if (!isPayer && !isParticipant) return const SizedBox.shrink();

              double share = 0;
              if (splits != null && splits.containsKey(member.id)) {
                share = splits[member.id]!;
              } else if (isParticipant && (expense.splitType == 'EQUAL' || expense.splitType == null)) {
                share = totalAmount / participants.length.toDouble();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: sunken, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                                style: AppTypography.bodyMuted.copyWith(color: ink, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.shortName,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyEmphasis.copyWith(color: ink),
                                ),
                                if (isPayer)
                                  Text('Paid the bill', style: AppTypography.caption.copyWith(color: AppColors.positive)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('₹${share.toStringAsFixed(2)}', style: AppTypography.amountSmall.copyWith(color: inkFaint)),
                  ],
                ),
              );
            })
          else
            Center(child: Text('Loading split details…', style: AppTypography.bodyMuted.copyWith(color: inkFaint))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
          Text(value, style: AppTypography.bodyEmphasis.copyWith(color: ink)),
        ],
      ),
    );
  }
}
