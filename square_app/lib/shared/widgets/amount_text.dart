import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';

enum AmountSign { neutral, positive, negative }

/// Displays a formatted Indian-rupee amount using the app's amount type
/// scale. Tapping shows a styled tooltip with the value in Indian words
/// (e.g. "2 crore 20 lakh 50 thousand").
class AmountText extends StatefulWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.sign = AmountSign.neutral,
    this.showPaise = false,
    this.showSignPrefix = true,
    this.tooltipTextColor,
    this.tooltipBgColor,
  });

  final double amount;

  /// Defaults to [AppTypography.amountInline] when omitted; override for
  /// display-size contexts (e.g. [AppTypography.displayAmount]).
  final TextStyle? style;

  /// Colors the amount and, when [showSignPrefix] is true, prefixes it with
  /// +/− — one component handling "+₹500" vs "−₹2,450" consistently.
  final AmountSign sign;
  final bool showPaise;
  final bool showSignPrefix;

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
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.tooltipBgColor ?? theme.colorScheme.inverseSurface;
    final fgColor = widget.tooltipTextColor ?? theme.colorScheme.onInverseSurface;

    final signColor = switch (widget.sign) {
      AmountSign.positive => AppColors.positive,
      AmountSign.negative => AppColors.negative,
      AmountSign.neutral => isDark ? AppColors.inkDark : AppColors.ink,
    };
    final prefix = widget.showSignPrefix
        ? switch (widget.sign) {
            AmountSign.positive => '+',
            AmountSign.negative => '−',
            AmountSign.neutral => '',
          }
        : '';

    // Respect an explicit color the caller already set on `style` (e.g. a
    // dark hero card inverting to a light fill needs light text regardless
    // of sign) — only fall back to the sign-derived color when none was set.
    final effectiveColor = widget.style?.color ?? signColor;
    final baseStyle = (widget.style ?? AppTypography.amountInline).copyWith(color: effectiveColor);
    final words = amountToIndianWords(widget.amount);
    // Neutral (the default) shows the real signed value — formatInr already
    // prepends "-" for negative amounts, so a deficit reads as a deficit.
    // Positive/negative are for callers with an always-positive magnitude who
    // want a synthetic +/- to convey direction (e.g. "you lent" vs "you owe").
    final formatted = widget.sign == AmountSign.neutral
        ? formatInr(widget.amount, showPaise: widget.showPaise)
        : '$prefix${formatInr(widget.amount.abs(), showPaise: widget.showPaise)}';

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      textStyle: AppTypography.bodyMuted.copyWith(color: fgColor, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: GestureDetector(
        onTap: _showTooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatted, style: baseStyle),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline_rounded,
              size: (baseStyle.fontSize ?? 16) * 0.5,
              color: effectiveColor.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
