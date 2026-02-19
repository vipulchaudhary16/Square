import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Top Left Blob (Purple)
        Positioned(
          top: -100,
          left: -100,
          child:
              Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.primary[900]!.withOpacity(0.2)
                          : AppColors.primary[200]!.withOpacity(0.4),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    duration: 7.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                  )
                  .move(
                    duration: 7.seconds,
                    begin: const Offset(0, 0),
                    end: const Offset(30, 30),
                  ),
        ),

        // Bottom Right Blob (Purple/Pinkish)
        Positioned(
          bottom: -100,
          right: -100,
          child:
              Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.purple[900]!.withOpacity(0.2)
                          : Colors.purple[200]!.withOpacity(0.4),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    duration: 5.seconds,
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(1, 1),
                  )
                  .move(
                    duration: 5.seconds,
                    begin: const Offset(0, 0),
                    end: const Offset(-20, -20),
                  ),
        ),

        // Backdrop Blur to smooth out the blobs
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
