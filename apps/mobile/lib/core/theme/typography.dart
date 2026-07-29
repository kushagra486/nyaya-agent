import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "colors.dart";

/// Typography scale from the design spec: Title 34, Section 26, Card Title 22,
/// Body 18, Caption 15 — all Inter, matching the spec's font choice.
class AppTypography {
  AppTypography._();

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
        height: 1.15,
      );

  static TextStyle get section => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.secondaryText,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.hintText,
      );

  /// Monospace-styled citation text (Relevant Statutes cards) — Inter has no
  /// true monospace variant, so this pairs with a system monospace fallback.
  static TextStyle get statuteCitation => const TextStyle(
        fontFamily: "monospace",
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.gold,
        height: 1.5,
      );
}
