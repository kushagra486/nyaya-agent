import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "../core/theme/colors.dart";
import "../core/theme/constants.dart";

enum StatusKind { analyzed, pending, closed }

class StatusChip extends StatelessWidget {
  final StatusKind kind;
  final String label;

  const StatusChip({super.key, required this.kind, required this.label});

  Color get _color {
    switch (kind) {
      case StatusKind.analyzed:
        return AppColors.greenStatus;
      case StatusKind.pending:
        return AppColors.yellowStatus;
      case StatusKind.closed:
        return AppColors.hintText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );

    if (kind == StatusKind.pending) return chip;

    // Gentle breathing glow on the "Analyzed" state per the motion spec.
    return chip
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .boxShadow(
          begin: BoxShadow(color: _color.withOpacity(0.0), blurRadius: 0),
          end: BoxShadow(color: _color.withOpacity(0.35), blurRadius: 14),
          duration: AppMotion.badgePulse,
        );
  }
}
