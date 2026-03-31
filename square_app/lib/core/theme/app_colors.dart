import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Pure Black & White with grays
  static const Map<int, Color> primary = {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFE5E5E5),
    300: Color(0xFFD4D4D4),
    400: Color(0xFFA3A3A3),
    500: Color(0xFF737373),
    600: Color(0xFF525252),
    700: Color(0xFF404040),
    800: Color(0xFF262626),
    900: Color(0xFF171717),
    950: Color(0xFF0A0A0A),
  };

  // Slate Palette (Neutrals) - Pure grayscale
  static const Map<int, Color> slate = {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFE5E5E5),
    300: Color(0xFFD4D4D4),
    400: Color(0xFFA3A3A3),
    500: Color(0xFF737373),
    600: Color(0xFF525252),
    700: Color(0xFF404040),
    800: Color(0xFF262626),
    900: Color(0xFF171717),
    950: Color(0xFF0A0A0A),
  };

  // Functional Colors - kept for semantic use
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color error = Color(0xFFDC2626); // Red
  static const Color success = Color(0xFF16A34A); // Green
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color info = Color(0xFF2563EB); // Blue

  // Semantic Aliases
  static final Color primaryBrand = primary[900]!; // Black as primary brand
  static const Color backgroundLight = Colors.white; // Pure white
  static const Color backgroundDark = Colors.black; // Pure black
  static const Color surfaceDark = Color(0xFF0A0A0A); // Near black
  static const Color cardDark = Color(0xFF171717); // Slightly lighter for cards

  // MaterialColor for Primary Swatch
  static final MaterialColor primaryMaterial = MaterialColor(
    primary[900]!.value,
    primary,
  );
}
