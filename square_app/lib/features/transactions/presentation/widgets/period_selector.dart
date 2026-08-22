import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/buttons/button_shell.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'period_selection.dart';

const _periodLabels = {
  PeriodType.week: 'Week',
  PeriodType.month: 'Month',
  PeriodType.year: 'Year',
  PeriodType.custom: 'Custom',
};

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selection,
    required this.onChanged,
    required this.transactionCount,
  });

  final PeriodSelection selection;
  final ValueChanged<PeriodSelection> onChanged;
  final int transactionCount;

  Future<void> _pickCustomRange(BuildContext context) async {
    DateTime start = selection.startDate;
    DateTime end = selection.endDate;

    await AppBottomSheet.show(
      context,
      title: 'Custom range',
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickStart() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime(2000),
                lastDate: end,
              );
              if (picked != null) setState(() => start = picked);
            }

            Future<void> pickEnd() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: end,
                firstDate: start,
                lastDate: DateTime(2101),
              );
              if (picked != null) setState(() => end = picked);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(label: 'Start date', date: start, onTap: pickStart),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _DateField(label: 'End date', date: end, onTap: pickEnd),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    text: 'Apply',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onChanged(selection.withCustomRange(start, end));
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final onInk = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;

    return Column(
      children: [
        Row(
          children: PeriodType.values.map((type) {
            final isSelected = selection.type == type;
            return Expanded(
              child: ButtonShell(
                onTap: () {
                  if (type == PeriodType.custom) {
                    _pickCustomRange(context);
                  } else {
                    onChanged(selection.withType(type));
                  }
                },
                borderRadius: AppRadius.sm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      _periodLabels[type]!,
                      style: AppTypography.bodyMuted.copyWith(
                        color: isSelected ? onInk : inkFaint,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                enabled: selection.supportsNavigation,
                onTap: () => onChanged(selection.previous()),
              ),
              Column(
                children: [
                  Text(selection.label, style: AppTypography.cardHeading.copyWith(color: ink)),
                  const SizedBox(height: 2),
                  Text(
                    '$transactionCount TRANSACTIONS',
                    style: AppTypography.label.copyWith(color: inkFaint),
                  ),
                ],
              ),
              _NavButton(
                icon: Icons.chevron_right,
                enabled: selection.supportsNavigation,
                onTap: () => onChanged(selection.next()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: ButtonShell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.sm,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(icon, size: 22, color: enabled ? ink : inkFaint),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: inkFaint)),
        const SizedBox(height: AppSpacing.sm),
        ButtonShell(
          onTap: onTap,
          borderRadius: AppRadius.md,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: sunken,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: line),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: inkFaint),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, y').format(date),
                    style: AppTypography.body.copyWith(color: ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
