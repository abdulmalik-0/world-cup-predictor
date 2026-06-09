import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/widgets/animated_background.dart';

/// App-wide living background — an animated motion canvas (FIFA World Cup 2026
/// NYNJ vibe): deep navy base with drifting blue + gold glows and floating
/// particles. Replaces the old static flags collage.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(child: child);
  }
}
