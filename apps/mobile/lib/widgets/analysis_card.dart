import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "../core/theme/typography.dart";
import "../core/theme/constants.dart";
import "glass_card.dart";

class AnalysisCard extends StatelessWidget {
  final String title;
  final Widget child;
  final int index;

  const AnalysisCard({super.key, required this.title, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.largeCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: AppMotion.cardEnter)
        .slideY(begin: 0.06, end: 0, duration: AppMotion.cardEnter, curve: Curves.easeOutCubic);
  }
}
