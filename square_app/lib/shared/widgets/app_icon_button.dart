import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'buttons/button_shell.dart';

/// Circular icon-only control. 40x40 default touch target (≥ accessibility
/// minimum) regardless of the icon's visual size.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  /// Filled = subtle sunken background (use on a plain surface so the
  /// tappable area reads clearly, e.g. an app-bar close button).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.inkDark : AppColors.ink;
    final bg = filled
        ? (isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken)
        : Colors.transparent;

    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: ButtonShell(
        onTap: onPressed,
        borderRadius: size / 2,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );
  }
}
