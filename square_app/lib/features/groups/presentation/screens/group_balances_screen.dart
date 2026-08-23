import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/group_model.dart';
import '../../data/group_repository.dart';
import '../groups_provider.dart';

class GroupBalancesScreen extends ConsumerWidget {
  const GroupBalancesScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(groupDetailsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Balances')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorState(message: err.toString()),
        data: (details) => _BalancesList(groupId: groupId, details: details),
      ),
    );
  }
}

class _BalancesList extends ConsumerWidget {
  const _BalancesList({required this.groupId, required this.details});

  final String groupId;
  final GroupDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).value?.id;
    final sortedDebts = _sortDebtsInvolvingUserFirst(details.debts, currentUserId);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupDetailsProvider(groupId));
        try {
          await ref.read(groupDetailsProvider(groupId).future);
        } catch (_) {}
      },
      child: details.debts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Center(
                    child: AppEmptyState(icon: Icons.check_circle, title: 'Everyone is settled up'),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              itemCount: sortedDebts.length,
              itemBuilder: (context, index) {
                final debt = sortedDebts[index];
                final fromUser = details.members.firstWhere(
                  (m) => m.id == debt.from,
                  orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
                );
                final toUser = details.members.firstWhere(
                  (m) => m.id == debt.to,
                  orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
                );
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final ink = isDark ? AppColors.inkDark : AppColors.ink;
                final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
                final line = _debtLineText(debt, currentUserId, fromUser, toUser);
                final canSettle = debt.from == currentUserId;

                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InitialsAvatar(name: fromUser.displayName),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              line.text,
                              style: AppTypography.body.copyWith(color: ink),
                            ),
                          ),
                          AmountText(
                            amount: debt.amount,
                            sign: line.sign,
                            showSignPrefix: false,
                            style: AppTypography.amountInline,
                          ),
                        ],
                      ),
                      if (canSettle) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _showSettleSheet(context, ref, groupId, toUser, debt.amount),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync_alt, size: 14, color: inkFaint),
                                const SizedBox(width: 4),
                                Text('Settle', style: AppTypography.bodyEmphasis.copyWith(color: ink)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showSettleSheet(BuildContext context, WidgetRef ref, String groupId, GroupMember toUser, double maxAmount) {
    final amountController = TextEditingController(text: maxAmount.toStringAsFixed(2));
    bool isSubmitting = false;
    String? errorText;

    AppBottomSheet.show(
      context,
      title: 'Settle up',
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final ink = isDark ? AppColors.inkDark : AppColors.ink;
            final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
            final line = isDark ? AppColors.lineDark : AppColors.line;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(name: toUser.displayName),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Pay ${toUser.displayName}',
                          style: AppTypography.cardHeading.copyWith(color: ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Amount', style: AppTypography.label.copyWith(color: inkFaint)),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: line),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.body.copyWith(color: ink),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.body.copyWith(color: ink),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      ),
                      onChanged: (_) => setState(() => errorText = null),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'You owe ${toUser.displayName} up to ₹${maxAmount.toStringAsFixed(2)}',
                    style: AppTypography.caption.copyWith(color: inkFaint),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(errorText!, style: AppTypography.errorText.copyWith(color: AppColors.negative)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: 'Settle',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final parsed = double.tryParse(amountController.text.trim());
                      if (parsed == null || parsed <= 0) {
                        setState(() => errorText = 'Enter a valid amount');
                        return;
                      }
                      if (parsed > maxAmount + 0.01) {
                        setState(() => errorText = 'Cannot be more than ₹${maxAmount.toStringAsFixed(2)}');
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        await ref.read(groupRepositoryProvider).settle(groupId, toUser.id, parsed);
                        ref.invalidate(groupDetailsProvider(groupId));
                        ref.invalidate(groupExpensesProvider("$groupId|"));
                        if (context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Settled ₹${parsed.toStringAsFixed(2)} with ${toUser.displayName}')),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isSubmitting = false;
                          errorText = '$e';
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

({String text, AmountSign sign}) _debtLineText(
  Debt debt,
  String? currentUserId,
  GroupMember fromUser,
  GroupMember toUser,
) {
  if (debt.from == currentUserId) {
    return (text: 'You owe ${toUser.displayName}', sign: AmountSign.negative);
  } else if (debt.to == currentUserId) {
    return (text: '${fromUser.displayName} owes you', sign: AmountSign.positive);
  } else {
    return (text: '${fromUser.displayName} owes ${toUser.displayName}', sign: AmountSign.neutral);
  }
}

List<Debt> _sortDebtsInvolvingUserFirst(List<Debt> debts, String? currentUserId) {
  if (currentUserId == null) return debts;
  final mine = <Debt>[];
  final others = <Debt>[];
  for (final debt in debts) {
    if (debt.from == currentUserId || debt.to == currentUserId) {
      mine.add(debt);
    } else {
      others.add(debt);
    }
  }
  return [...mine, ...others];
}
