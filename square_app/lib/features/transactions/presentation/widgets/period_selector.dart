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

/// A single-row, tappable summary of the current period (e.g. "August 2026
/// · 21 transactions") that opens a bottom sheet for switching period type,
/// stepping to the next/previous one, or picking a custom range. Kept
/// deliberately compact — one row instead of a permanently-visible
/// segmented-toggle-plus-nav layout — since this is often pinned above
/// scrolling content.
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

  void _showPeriodSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Select period',
      isScrollControlled: true,
      builder: (sheetContext) => _PeriodSheet(selection: selection, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return ButtonShell(
      onTap: () => _showPeriodSheet(context),
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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      selection.label,
                      style: AppTypography.bodyEmphasis.copyWith(color: ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: inkFaint),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('$transactionCount transactions', style: AppTypography.caption.copyWith(color: inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _PeriodSheet extends StatefulWidget {
  const _PeriodSheet({required this.selection, required this.onChanged});

  final PeriodSelection selection;
  final ValueChanged<PeriodSelection> onChanged;

  @override
  State<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends State<_PeriodSheet> {
  late bool _pickingCustomRange;
  late DateTime _customStart;
  late DateTime _customEnd;

  @override
  void initState() {
    super.initState();
    _pickingCustomRange = widget.selection.type == PeriodType.custom;
    _customStart = widget.selection.customStart ?? widget.selection.startDate;
    _customEnd = widget.selection.customEnd ?? widget.selection.endDate;
  }

  void _apply(PeriodSelection next) {
    widget.onChanged(next);
    Navigator.of(context).pop();
  }

  Future<void> _pickCustomStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStart,
      firstDate: DateTime(2000),
      lastDate: _customEnd,
    );
    if (picked != null) setState(() => _customStart = picked);
  }

  Future<void> _pickCustomEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEnd,
      firstDate: _customStart,
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _customEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final onInk = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: PeriodType.values.map((type) {
              final isSelected =
                  _pickingCustomRange ? type == PeriodType.custom : widget.selection.type == type;
              return Expanded(
                child: ButtonShell(
                  onTap: () {
                    if (type == PeriodType.custom) {
                      setState(() => _pickingCustomRange = true);
                    } else {
                      _apply(widget.selection.withType(type));
                    }
                  },
                  borderRadius: AppRadius.sm,
                  child: Container(
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
          const SizedBox(height: AppSpacing.lg),
          if (_pickingCustomRange) ...[
            Row(
              children: [
                Expanded(child: _DateField(label: 'Start date', date: _customStart, onTap: _pickCustomStart)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _DateField(label: 'End date', date: _customEnd, onTap: _pickCustomEnd)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Apply',
              onPressed: () => _apply(widget.selection.withCustomRange(_customStart, _customEnd)),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
              decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(
                    icon: Icons.chevron_left,
                    enabled: widget.selection.supportsNavigation,
                    onTap: () => _apply(widget.selection.previous()),
                  ),
                  Text(widget.selection.label, style: AppTypography.cardHeading.copyWith(color: ink)),
                  _NavButton(
                    icon: Icons.chevron_right,
                    enabled: widget.selection.supportsNavigation,
                    onTap: () => _apply(widget.selection.next()),
                  ),
                ],
              ),
            ),
        ],
      ),
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
