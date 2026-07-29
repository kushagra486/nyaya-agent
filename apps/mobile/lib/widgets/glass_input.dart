import "package:flutter/material.dart";
import "../core/theme/colors.dart";
import "../core/theme/constants.dart";
import "../core/theme/typography.dart";

class GlassInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const GlassInput({
    super.key,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondarySurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(maxLines > 1 ? AppRadius.smallCard : AppRadius.input),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTypography.body.copyWith(color: AppColors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.caption,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
