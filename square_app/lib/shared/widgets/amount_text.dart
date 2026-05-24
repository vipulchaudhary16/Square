import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

/// Displays a formatted Indian-rupee amount.
///
/// Tapping the amount shows a styled tooltip with the value in
/// Indian words (e.g. "2 crore 20 lakh 50 thousand").
class AmountText extends StatefulWidget {
  const AmountText({
    super.key,
    required this.amount,
    required this.style,
    this.showPaise = false,
    this.tooltipTextColor,
    this.tooltipBgColor,
  });

  final double amount;
  final TextStyle style;
  final bool showPaise;

  /// Overrides for tooltip colours; defaults to theme values when null.
  final Color? tooltipTextColor;
  final Color? tooltipBgColor;

  @override
  State<AmountText> createState() => _AmountTextState();
}

class _AmountTextState extends State<AmountText> {
  final GlobalKey _tooltipKey = GlobalKey();

  void _showTooltip() {
    final dynamic tooltip = _tooltipKey.currentState;
    tooltip?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.tooltipBgColor ??
        theme.colorScheme.inverseSurface;
    final fgColor = widget.tooltipTextColor ??
        theme.colorScheme.onInverseSurface;

    final words = amountToIndianWords(widget.amount);
    final formatted = formatInr(widget.amount, showPaise: widget.showPaise);

    return Tooltip(
      key: _tooltipKey,
      triggerMode: TooltipTriggerMode.manual,
      message: words,
      preferBelow: false,
      verticalOffset: 14,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: fgColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: GestureDetector(
        onTap: _showTooltip,
        child: Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatted, style: widget.style),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline_rounded,
              size: (widget.style.fontSize ?? 16) * 0.55,
              color: (widget.style.color ?? fgColor).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
