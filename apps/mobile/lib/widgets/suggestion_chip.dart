import "package:flutter/material.dart";
import "../core/theme/colors.dart";
import "../core/theme/constants.dart";

class SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const SuggestionChip({super.key, required this.label, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            ),
            child: Text(
              label,
              style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
