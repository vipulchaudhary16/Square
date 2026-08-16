import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'buttons/button_shell.dart';

/// Lowest-emphasis action: no border, no fill. Use for tertiary actions like
/// "Skip", inline links, or a dialog's dismiss action.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Tightens height/typography for inline contexts (e.g. dialog actions).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.inkDark : AppColors.ink;

    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: ButtonShell(
        onTap: onPressed,
        borderRadius: AppRadius.sm,
        child: Container(
          height: compact ? 36 : 44,
          padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.md : AppSpacing.lg),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 16),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                text,
                style: (compact ? AppTypography.buttonCompact : AppTypography.button)
                    .copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
