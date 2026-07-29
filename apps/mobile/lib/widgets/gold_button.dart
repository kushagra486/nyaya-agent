import "package:flutter/material.dart";
import "../core/theme/colors.dart";
import "../core/theme/constants.dart";
import "../core/theme/typography.dart";

class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 72,
    this.icon,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        child: AnimatedOpacity(
          opacity: disabled && !widget.loading ? 0.5 : 1.0,
          duration: AppMotion.buttonPress,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.newCaseGradientStart, AppColors.newCaseGradientEnd],
              ),
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [AppColors.goldGlow()],
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black87),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.black87, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: AppTypography.cardTitle.copyWith(color: Colors.black87, fontSize: 18),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
