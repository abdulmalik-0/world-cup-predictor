import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/widgets/optional_image.dart';

/// A living app-wide background. Uses the World Cup 26 banner with a slow
/// Ken-Burns motion behind a dark scrim so content stays readable.
/// Falls back to a gradient + glows if the image is missing.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  // Dark navy scrim: darker at the edges, clearer in the middle so the
  // banner (trophy + 26) shows through.
  static const _scrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xE60A1622),
      Color(0xA00A1622),
      Color(0xE60A1622),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Image base with slow Ken-Burns motion (gradient fallback).
        const OptionalImage(
          path: 'assets/images/background1.jpeg',
          fit: BoxFit.cover,
          cacheWidth: 1280,
          fallback: _GradientFallback(),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.12, duration: 26000.ms, curve: Curves.easeInOut)
            .move(begin: Offset.zero, end: const Offset(-12, -18), duration: 26000.ms),

        // 2) Dark scrim for readability.
        const DecoratedBox(decoration: BoxDecoration(gradient: _scrim)),

        // 3) A couple of faint drifting footballs for extra life.
        _ball(top: 130, right: 26, size: 24, dur: 3400),
        _ball(bottom: 200, left: 28, size: 18, dur: 4400),

        child,
      ],
    );
  }

  Widget _ball({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required int dur,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Icon(
          Icons.sports_soccer,
          size: size,
          color: Colors.white.withValues(alpha: 0.06),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -22, duration: dur.ms, curve: Curves.easeInOut)
            .rotate(begin: 0, end: 0.05, duration: dur.ms),
      ),
    );
  }
}

/// Shown when the background image asset is not present.
class _GradientFallback extends StatelessWidget {
  const _GradientFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient),
        ),
        _glow(top: -110, right: -90, size: 360, color: AppTheme.pitchGreen),
        _glow(bottom: -130, left: -90, size: 340, color: AppTheme.accentGold),
      ],
    );
  }

  Widget _glow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
