import "dart:ui";
import "package:flutter/material.dart";
import "../core/theme/colors.dart";

class FloatingChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingChatButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: AppColors.gold.withOpacity(0.9),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [AppColors.goldGlow()]),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.black87, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
