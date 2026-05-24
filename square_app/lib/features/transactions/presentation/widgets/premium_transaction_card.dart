import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum TransactionType { expense, income, investment, loan }

class PremiumTransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;
  final bool isPositive;
  final VoidCallback? onTap;

  const PremiumTransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    this.isPositive = false,
    this.onTap,
  });

  Color get _typeColor {
    switch (type) {
      case TransactionType.expense:
        return const Color(0xFFef4444);
      case TransactionType.income:
        return const Color(0xFF22c55e);
      case TransactionType.investment:
        return const Color(0xFF8b5cf6);
      case TransactionType.loan:
        return const Color(0xFFf59e0b);
    }
  }

  IconData get _icon {
    switch (type) {
      case TransactionType.expense:
        return LucideIcons.receipt;
      case TransactionType.income:
        return LucideIcons.trendingUp;
      case TransactionType.investment:
        return LucideIcons.barChart2;
      case TransactionType.loan:
        return LucideIcons.arrowLeftRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor;

    final amountColor = isPositive
        ? const Color(0xFF22c55e)
        : (type == TransactionType.expense
            ? const Color(0xFFef4444)
            : (isDark ? Colors.white : const Color(0xFF0A0A0A)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: typeColor.withOpacity(0.06),
          highlightColor: typeColor.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1C1C1C)
                    : const Color(0xFFEFEFEF),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 13),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (category != null && category!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor
                                    .withOpacity(isDark ? 0.18 : 0.10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category!,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF555555)
                                  : const Color(0xFFAAAAAA),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount + badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPositive ? '+' : '−'}₹${_formatAmount(amount)}',
                      style: GoogleFonts.dmMono(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        subtitle.toUpperCase(),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF4A4A4A)
                              : const Color(0xFFAAAAAA),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.year == d.year) return DateFormat('MMM d').format(d);
    return DateFormat('MMM d, y').format(d);
  }

  String _formatAmount(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
