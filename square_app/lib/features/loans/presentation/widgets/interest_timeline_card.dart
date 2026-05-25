import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/currency_formatter.dart';

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
    if (widget.timeline.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF111111)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.trending_up,
                      size: 18,
                      color: Colors.orange[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accrued Interest',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          formatInr(widget.accruedInterest),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.timeline.length,
                itemBuilder: (_, i) {
                  final entry = widget.timeline[i];
                  final date = DateTime.parse(entry['date'] as String);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('dd MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${formatInr((entry['daily_interest'] as num).toDouble())}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: Text(
                            formatInr(
                                (entry['cumulative'] as num).toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
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
