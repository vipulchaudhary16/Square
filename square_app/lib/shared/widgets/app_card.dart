import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'buttons/button_shell.dart';

/// Flat screen-level surface (a section wrapper, not a "card"). Use for
/// grouping content that shouldn't visually compete with real cards.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding,
      color: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
      child: child,
    );
  }
}

/// The base card: bordered, no shadow by default. Set [elevated] only when a
/// card needs to visually lift off a sunken background — most screens should
/// not need it.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.elevated = false,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// A tappable [AppCard]: adds ripple feedback and an optional trailing
/// chevron affordance for navigation rows (group row, contact row, etc).
class AppInteractiveCard extends StatelessWidget {
  const AppInteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.showChevron = false,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool showChevron;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final faint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ButtonShell(
          onTap: onTap,
          borderRadius: radius.topLeft.x,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                Expanded(child: child),
                if (showChevron) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.chevron_right_rounded, color: faint, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
