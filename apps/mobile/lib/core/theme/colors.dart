import "package:flutter/material.dart";

/// Nyaya-Agent color tokens, ported 1:1 from the design spec.
class AppColors {
  AppColors._();

  static const background = Color(0xFF090C15);
  static const primarySurface = Color(0xFF161C2D);
  static const secondarySurface = Color(0xFF20283A);
  static const card = Color(0xFF252E43);
  static const border = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)

  static const gold = Color(0xFFE4B326);
  static const goldLight = Color(0xFFFFD665);
  static const goldDark = Color(0xFFB88700);

  static const greenStatus = Color(0xFF35D07F);
  static const yellowStatus = Color(0xFFF5C542);

  static const white = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xFFB8C1D1);
  static const hintText = Color(0xFF7E889A);

  static const chatBubbleUser = Color(0xFF293B80);
  static const chatBubbleAi = Color(0xFF2B3345);

  // New Case button gradient
  static const newCaseGradientStart = Color(0xFFFFD84C);
  static const newCaseGradientEnd = Color(0xFFC89600);

  // Aurora background blob hues
  static const auroraBlue = Color(0xFF3B5BFF);
  static const auroraPurple = Color(0xFF8B3BFF);
  static const auroraGold = Color(0xFFE4B326);

  static const error = Color(0xFFFF6B6B);

  static BoxShadow cardShadow() => BoxShadow(
        color: Colors.black.withOpacity(0.35),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );

  static BoxShadow goldGlow() => BoxShadow(
        color: gold.withOpacity(0.30),
        blurRadius: 20,
        spreadRadius: 1,
      );

  static BoxShadow greenGlow() => BoxShadow(
        color: greenStatus.withOpacity(0.25),
        blurRadius: 20,
        spreadRadius: 1,
      );
}
