import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Violet)
  static const Map<int, Color> primary = {
    50: Color(0xFFf5f3ff),
    100: Color(0xFFede9fe),
    200: Color(0xFFddd6fe),
    300: Color(0xFFc4b5fd),
    400: Color(0xFFa78bfa),
    500: Color(0xFF8b5cf6),
    600: Color(0xFF7c3aed),
    700: Color(0xFF6d28d9),
    800: Color(0xFF5b21b6),
    900: Color(0xFF4c1d95),
    950: Color(0xFF2e1065),
  };

  // Slate Palette (Neutrals) - Using standard slate colors
  static const Map<int, Color> slate = {
    50: Color(0xFFf8fafc),
    100: Color(0xFFf1f5f9),
    200: Color(0xFFe2e8f0),
    300: Color(0xFFcbd5e1),
    400: Color(0xFF94a3b8),
    500: Color(0xFF64748b),
    600: Color(0xFF475569),
    700: Color(0xFF334155),
    800: Color(0xFF1e293b),
    900: Color(0xFF0f172a),
    950: Color(0xFF020617),
  };

  // Functional Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color error = Color(0xFFef4444); // Red-500
  static const Color success = Color(0xFF22c55e); // Green-500
  static const Color warning = Color(0xFFf59e0b); // Amber-500
  static const Color info = Color(0xFF3b82f6); // Blue-500

  // Semantic Aliases
  static final Color primaryBrand = primary[600]!;
  static final Color backgroundLight = slate[50]!;
  // Richer dark background (Deep Violet-Black)
  static const Color backgroundDark = Color(0xFF0f0a1e); // Very deep violet
  static const Color surfaceDark = Color(0xFF1a142e); // Creating depth
  static const Color cardDark = Color(0xFF231b3a); // Lighter for cards

  // MaterialColor for Primary Swatch
  static final MaterialColor primaryMaterial = MaterialColor(
    primary[500]!.value,
    primary,
  );
}
