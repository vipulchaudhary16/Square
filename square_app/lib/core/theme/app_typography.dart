import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's type scale. Sora carries display/headings/amounts; Inter
/// carries everything read at body size or smaller. Colors are omitted here
/// (applied via `.copyWith(color: ...)` at the call site from theme tokens)
/// except where a role has one canonical color (helper/error).
class AppTypography {
  AppTypography._();

  static TextStyle _sora(double size, FontWeight weight, {double? height, double? letterSpacing}) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle _inter(double size, FontWeight weight, {double? height, double? letterSpacing}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ---- Amounts (Sora, tabular where it matters) ----
  static TextStyle get displayAmount =>
      _sora(34, FontWeight.w600, height: 1.15, letterSpacing: -0.4)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle get amountLarge =>
      _sora(24, FontWeight.w600, height: 1.2, letterSpacing: -0.3)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle get amountInline =>
      _sora(15, FontWeight.w600, height: 1.3)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle get amountSmall =>
      _sora(13, FontWeight.w600, height: 1.3)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  // ---- Headings (Sora) ----
  static TextStyle get screenTitle => _sora(22, FontWeight.w600, height: 1.25, letterSpacing: -0.2);
  static TextStyle get sectionHeading => _sora(15, FontWeight.w600, height: 1.3);

  // ---- Content (Inter) ----
  static TextStyle get cardHeading => _inter(15, FontWeight.w600, height: 1.3);
  static TextStyle get body => _inter(14, FontWeight.w400, height: 1.45);
  static TextStyle get bodyEmphasis => _inter(14, FontWeight.w600, height: 1.45);
  static TextStyle get bodyMuted => _inter(13, FontWeight.w400, height: 1.4);
  static TextStyle get label =>
      _inter(12, FontWeight.w600, height: 1.3, letterSpacing: 0.3);
  static TextStyle get caption => _inter(12, FontWeight.w400, height: 1.35);
  static TextStyle get helper => _inter(12, FontWeight.w400, height: 1.35);
  static TextStyle get errorText => _inter(12, FontWeight.w500, height: 1.35);
  static TextStyle get button => _inter(15, FontWeight.w600, height: 1.2);
  static TextStyle get buttonCompact => _inter(14, FontWeight.w600, height: 1.2);
}
