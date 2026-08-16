import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Calm, monochrome ambient background for the auth screen. Replaces the
/// previous animated purple blobs, which broke the app's monochrome
/// identity — this is a static, subtle radial tint instead.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.2,
          colors: isDark
              ? [AppColors.surfaceRaisedDark, AppColors.surfaceSunkenDark]
              : [AppColors.surfaceSunken, AppColors.surface],
        ),
      ),
    );
  }
}
