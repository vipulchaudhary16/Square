import 'package:flutter/material.dart';

/// Monochrome-first palette. [ink]/[surface] family is the backbone of every
/// screen; color is reserved for [positive]/[negative]/[warning] semantics
/// and the small [categoryAccents] set.
class AppColors {
  // ---- Grayscale ramp (light) ----
  static const Color ink = Color(0xFF111111);
  static const Color inkMuted = Color(0xFF4B4B4B);
  static const Color inkFaint = Color(0xFF8A8A8A);
  static const Color line = Color(0xFFE4E4E4);
  static const Color lineStrong = Color(0xFFCFCFCF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFFAFAFA);

  // ---- Grayscale ramp (dark) ----
  static const Color inkDark = Color(0xFFF5F5F5);
  static const Color inkMutedDark = Color(0xFFA0A0A0);
  static const Color inkFaintDark = Color(0xFF6E6E6E);
  static const Color lineDark = Color(0xFF262626);
  static const Color lineStrongDark = Color(0xFF383838);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color surfaceSunkenDark = Color(0xFF0A0A0A);
  static const Color surfaceRaisedDark = Color(0xFF1C1C1C);

  // ---- Semantic (same in both themes; used sparingly) ----
  static const Color positive = Color(0xFF1E8E5A); // income / credit
  static const Color negative = Color(0xFFD64545); // expense / debit
  static const Color warning = Color(0xFFB8792E);
  static const Color positiveSoft = Color(0xFFE7F5EE);
  static const Color negativeSoft = Color(0xFFFBEBEB);
  static const Color warningSoft = Color(0xFFFAF1E4);
  static const Color positiveSoftDark = Color(0xFF12291F);
  static const Color negativeSoftDark = Color(0xFF2E1717);
  static const Color warningSoftDark = Color(0xFF2B2115);

  /// A small curated accent set for category tinting, since categories carry
  /// no color from the backend. Pick deterministically via [categoryAccent].
  static const List<Color> categoryAccents = [
    Color(0xFF5B6EE1), // indigo
    Color(0xFF2E9E86), // teal
    Color(0xFFC97A3D), // ochre
    Color(0xFF9457C9), // violet
    Color(0xFF3D8EC9), // steel blue
    Color(0xFFB25C82), // mauve
  ];

  static Color categoryAccent(String name) {
    if (name.isEmpty) return categoryAccents.first;
    final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return categoryAccents[hash % categoryAccents.length];
  }

  // ---- Legacy maps kept for compatibility with existing call sites ----
  // Values realigned to the new ramp so unmigrated screens still shift
  // toward the new look; migrate call sites to the tokens above over time.
  static const Map<int, Color> primary = {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFE4E4E4),
    300: Color(0xFFCFCFCF),
    400: Color(0xFFA0A0A0),
    500: Color(0xFF8A8A8A),
    600: Color(0xFF6E6E6E),
    700: Color(0xFF4B4B4B),
    800: Color(0xFF262626),
    900: Color(0xFF111111),
    950: Color(0xFF0A0A0A),
  };

  static const Map<int, Color> slate = primary;

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color error = negative;
  static const Color success = positive;
  static const Color info = Color(0xFF3D8EC9);

  static const Color primaryBrand = ink;
  static const Color backgroundLight = surface;
  static const Color backgroundDark = surfaceSunkenDark;
  static const Color cardDark = surfaceRaisedDark;

  static final MaterialColor primaryMaterial = MaterialColor(
    primary[900]!.toARGB32(),
    primary,
  );
}
