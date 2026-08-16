import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'buttons/button_shell.dart';

/// The one place [AppColors.negative] is allowed to fill a button. Reserve
/// for irreversible actions: delete, remove, leave group.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.filled = false,
    this.fullWidth = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Filled = high-emphasis destructive (confirm-delete dialogs). Outlined
  /// (default) = lower-emphasis, for inline "Delete" rows.
  final bool filled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    const fg = AppColors.negative;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: ButtonShell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadius.md,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: filled ? AppColors.negativeSoft : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: filled ? null : Border.all(color: fg.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.button.copyWith(color: fg),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
