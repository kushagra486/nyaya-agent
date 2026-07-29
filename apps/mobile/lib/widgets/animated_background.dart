import "dart:math" as math;
import "dart:ui";
import "package:flutter/material.dart";
import "../core/theme/colors.dart";

/// Slow-drifting blurred color blobs behind the UI, like an iOS Dynamic
/// Island wallpaper. Purely decorative — sits behind all screen content.
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One full drift cycle roughly every ~18 loops of the base motion unit,
    // scaled up so the blobs move "very slowly" per the spec (15-20s feel
    // per micro-oscillation, minutes for the full controller loop).
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                children: [
                  _blob(
                    context,
                    color: AppColors.auroraBlue,
                    dx: 0.15 + 0.08 * math.sin(t),
                    dy: 0.20 + 0.06 * math.cos(t),
                    size: 320,
                  ),
                  _blob(
                    context,
                    color: AppColors.auroraPurple,
                    dx: 0.75 + 0.07 * math.cos(t * 0.8),
                    dy: 0.55 + 0.09 * math.sin(t * 0.8),
                    size: 280,
                  ),
                  _blob(
                    context,
                    color: AppColors.auroraGold,
                    dx: 0.45 + 0.09 * math.sin(t * 1.3),
                    dy: 0.85 + 0.05 * math.cos(t * 1.3),
                    size: 260,
                  ),
                ],
              );
            },
          ),
          // Frost the blobs down so foreground content stays legible.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _blob(BuildContext context, {required Color color, required double dx, required double dy, required double size}) {
    final screen = MediaQuery.of(context).size;
    return Positioned(
      left: dx * screen.width - size / 2,
      top: dy * screen.height - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.35),
        ),
      ),
    );
  }
}
