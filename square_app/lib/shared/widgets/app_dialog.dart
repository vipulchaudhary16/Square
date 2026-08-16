import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'ghost_button.dart';
import 'destructive_button.dart';

/// A single dialog action. Use [isDestructive] for delete/remove/leave-type
/// confirmations — it renders via [DestructiveButton] rather than
/// [GhostButton].
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
}

/// Consistent confirmation/alert dialog: no default Material shadow ring,
/// properly spaced actions, monochrome by default.
class AppDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    required List<AppDialogAction> actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;

    return showDialog<T>(
      context: context,
      barrierColor: ink.withValues(alpha: 0.32),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardHeading.copyWith(color: ink)),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTypography.body.copyWith(color: inkMuted)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    actions[i].isDestructive
                        ? DestructiveButton(
                            text: actions[i].label,
                            fullWidth: false,
                            onPressed: () {
                              Navigator.of(context).pop();
                              actions[i].onPressed();
                            },
                          )
                        : GhostButton(
                            text: actions[i].label,
                            compact: true,
                            onPressed: () {
                              Navigator.of(context).pop();
                              actions[i].onPressed();
                            },
                          ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same dialog chrome (overlay tint, radius, padding, no shadow ring) but
  /// with an arbitrary body — use for short forms (e.g. "create category")
  /// instead of a full screen or bottom sheet. The builder gets its own
  /// BuildContext so it can call `Navigator.of(context).pop()` to dismiss.
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;

    return showDialog<T>(
      context: context,
      barrierColor: ink.withValues(alpha: 0.32),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: builder(context),
        ),
      ),
    );
  }
}
