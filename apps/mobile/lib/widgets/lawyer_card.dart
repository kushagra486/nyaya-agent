import "package:flutter/material.dart";
import "../core/theme/colors.dart";
import "../core/theme/constants.dart";
import "../core/theme/typography.dart";
import "../models/lawyer_model.dart";
import "glass_card.dart";
import "gold_button.dart";

class LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;
  final bool requested;
  final VoidCallback onRequestConsultation;
  final VoidCallback? onMessage;

  const LawyerCard({
    super.key,
    required this.lawyer,
    required this.requested,
    required this.onRequestConsultation,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.smallCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.gold,
                child: Text(
                  lawyer.initials,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(lawyer.name, style: AppTypography.cardTitle.copyWith(fontSize: 18))),
                        const SizedBox(width: 6),
                        if (lawyer.isVerified)
                          const Icon(Icons.verified_rounded, color: AppColors.greenStatus, size: 18),
                      ],
                    ),
                    if (lawyer.isVerified)
                      const Text("Verified Lawyer", style: TextStyle(color: AppColors.greenStatus, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text("Registration: ${lawyer.barCouncilRegNo}", style: AppTypography.caption),
          const SizedBox(height: 4),
          Text("Experience: ${lawyer.experienceYears} Years", style: AppTypography.caption),
          const SizedBox(height: 4),
          Text("Fee: ₹${lawyer.consultationFee.toStringAsFixed(0)}/hr", style: AppTypography.caption),
          const SizedBox(height: 16),
          GoldButton(
            label: requested ? "REQUEST SENT" : "SHARE CASE & REQUEST CONSULTATION",
            height: 52,
            onPressed: requested ? null : onRequestConsultation,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _outlineAction(icon: Icons.ios_share_rounded, label: "SHARE", onTap: () {})),
              const SizedBox(width: 10),
              Expanded(
                child: _outlineAction(icon: Icons.message_rounded, label: "MESSAGE", onTap: onMessage ?? () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outlineAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
