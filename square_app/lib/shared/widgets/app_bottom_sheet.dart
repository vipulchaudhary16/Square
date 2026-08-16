import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon_button.dart';

/// Consistent bottom-sheet chrome: drag handle, header (title + optional
/// close button), and standard content padding. Use this instead of calling
/// `showModalBottomSheet` directly so every sheet in the app matches.
class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    bool showClose = false,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: isDark ? AppColors.surfaceRaisedDark : AppColors.surface,
      barrierColor: (isDark ? AppColors.inkDark : AppColors.ink).withValues(alpha: 0.32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.lineStrongDark : AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (title != null || showClose)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: title != null
                            ? Text(
                                title,
                                style: AppTypography.sectionHeading.copyWith(
                                  color: isDark ? AppColors.inkDark : AppColors.ink,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (showClose)
                        AppIconButton(
                          icon: Icons.close_rounded,
                          size: 32,
                          iconSize: 18,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox(height: AppSpacing.sm),
              Flexible(child: builder(context)),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}
