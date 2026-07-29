import "dart:ui";
import "package:flutter/material.dart";
import "../core/theme/colors.dart";
import "../core/theme/constants.dart";

/// Frosted-glass container: BackdropFilter blur + translucent fill + subtle
/// white border, matching the spec's glass effect (blur 18, opacity 0.12,
/// border 1px rgba(255,255,255,.15)).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool withShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.largeCard,
    this.withShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppGlass.blurSigma, sigmaY: AppGlass.blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(AppGlass.opacity + 0.55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: AppGlass.borderWidth),
            boxShadow: withShadow ? [AppColors.cardShadow()] : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        splashColor: AppColors.gold.withOpacity(0.08),
        child: content,
      ),
    );
  }
}
