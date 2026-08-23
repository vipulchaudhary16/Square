import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A circular avatar showing a name's first initial, colored by the app's
/// fixed categorical accent set (keyed off the name) for a consistent,
/// deterministic per-person color across the app.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.categoryAccent(name);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.22 : 0.12), shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTypography.bodyEmphasis.copyWith(color: accent),
        ),
      ),
    );
  }
}
