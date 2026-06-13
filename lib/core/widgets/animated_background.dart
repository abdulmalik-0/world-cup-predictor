import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// "WE ARE 26" branded app background — recreated in code:
/// a black backdrop with the bold WE ARE 26 lockup + a real gold trophy,
/// plus creative touches: a pulsing gold glow, a sweeping shimmer over the
/// text, slow breathing motion, and a vignette/scrim so foreground content
/// stays readable.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key, this.child});

  final Widget? child;

  static const _gold = Color(0xFFE9B84A);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Black base (subtle warm center).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.15),
              radius: 1.3,
              colors: [Color(0xFF15110A), Color(0xFF050505), Color(0xFF000000)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // 2) Pulsing gold glow behind the lockup.
        IgnorePointer(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.7,
              heightFactor: 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.22),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.9, end: 1.12, duration: 3000.ms, curve: Curves.easeInOut)
                  .fadeIn(duration: 1200.ms),
            ),
          ),
        ),

        // 3) The WE ARE 26 lockup (breathing + shimmer sweep).
        IgnorePointer(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.82,
              heightFactor: 0.62,
              child: const _WeAre26Lockup()
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.03, duration: 5200.ms, curve: Curves.easeInOut),
            ),
          ),
        ),

        // 4) Vignette + readability scrim (dims top/bottom, lets center breathe).
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3000000),
                  Color(0x4D000000),
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        if (child != null) child!,
      ],
    );
  }
}

class _WeAre26Lockup extends StatelessWidget {
  const _WeAre26Lockup();

  static const _gold = Color(0xFFE9B84A);

  @override
  Widget build(BuildContext context) {
    const heavy = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -4,
      height: 0.9,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('WE ARE', style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 150,
            height: 0.9,
          )),
          // "2 [trophy] 6" — each digit centered in an equal-width box so the
          // gap on the left of the trophy equals the gap on the right.
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 230,
                child: Text(
                  '2',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 300,
                    height: 0.9,
                  ),
                ),
              ),
              Image.asset(
                'assets/images/trophy.png',
                height: 320,
                fit: BoxFit.contain,
              ),
              const SizedBox(
                width: 230,
                child: Text(
                  '6',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 300,
                    height: 0.9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('FIFA', style: heavy.copyWith(
            fontSize: 64,
            fontStyle: FontStyle.normal,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 2,
          )),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 3200.ms,
          delay: 1200.ms,
          color: _gold,
        ),
    );
  }
}
