import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/buttons/button_shell.dart';

class InterestTimelineCard extends StatefulWidget {
  final List<Map<String, dynamic>> timeline;
  final double accruedInterest;
  final bool isDark;

  const InterestTimelineCard({
    super.key,
    required this.timeline,
    required this.accruedInterest,
    required this.isDark,
  });

  @override
  State<InterestTimelineCard> createState() => _InterestTimelineCardState();
}

class _InterestTimelineCardState extends State<InterestTimelineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ButtonShell(
            onTap: widget.timeline.isEmpty ? null : () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadius.lg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 18, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Accrued Interest', style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
                        Text(
                          formatInr(widget.accruedInterest),
                          style: AppTypography.amountInline.copyWith(color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                  if (widget.timeline.isNotEmpty)
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: inkFaint, size: 18),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: isDark ? AppColors.lineDark : AppColors.line),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: widget.timeline.length,
                itemBuilder: (_, i) {
                  final entry = widget.timeline[i];
                  final isAggregated = entry.containsKey('period_interest');
                  final label = isAggregated
                      ? entry['date'] as String
                      : DateFormat('dd MMM').format(DateTime.parse(entry['date'] as String));
                  final interest =
                      ((isAggregated ? entry['period_interest'] : entry['daily_interest']) as num).toDouble();
                  final cumulative = (entry['cumulative'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Text(label, style: AppTypography.caption.copyWith(color: inkFaint)),
                        const Spacer(),
                        Text('+${formatInr(interest)}', style: AppTypography.caption.copyWith(color: AppColors.warning)),
                        const SizedBox(width: AppSpacing.lg),
                        SizedBox(
                          width: 84,
                          child: Text(
                            formatInr(cumulative),
                            style: AppTypography.caption.copyWith(color: ink, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
