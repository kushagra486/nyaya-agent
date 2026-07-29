import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "../core/theme/typography.dart";
import "../core/theme/constants.dart";
import "../models/case_model.dart";
import "glass_card.dart";
import "status_chip.dart";

class CaseCard extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback onTap;
  final int index;

  const CaseCard({super.key, required this.caseModel, required this.onTap, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final isAnalyzed = caseModel.status == CaseStatus.analyzed;
    final chip = isAnalyzed
        ? const StatusChip(kind: StatusKind.analyzed, label: "Analyzed")
        : const StatusChip(kind: StatusKind.pending, label: "Pending Review");

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.smallCard,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caseModel.title, style: AppTypography.cardTitle),
                const SizedBox(height: 10),
                chip,
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: AppMotion.cardEnter)
        .slideY(begin: 0.08, end: 0, duration: AppMotion.cardEnter, curve: Curves.easeOutCubic);
  }
}
