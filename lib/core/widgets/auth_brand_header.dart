import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:world_cup_predictor/core/widgets/malaz_logo.dart';
import 'package:world_cup_predictor/core/widgets/world_cup_logo.dart';

/// Logo + title block for login / register screens.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.subtitle,
  });

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: const WorldCupLogo(
            height: 150,
            assetPath: kWorldCupAuthLogo,
          )
              // Gentle floating + periodic golden shine on the trophy.
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -5, end: 5, duration: 2600.ms, curve: Curves.easeInOut)
              .shimmer(duration: 2600.ms, color: const Color(0x66E9B84A)),
        ),
        const SizedBox(height: 20),
        // "INVENU World Cup Arena" — INVENU rendered with the logo mark.
        Directionality(
          textDirection: TextDirection.ltr,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const MalazLogo(height: 34),
                const SizedBox(width: 8),
                Text(
                  'World Cup Arena',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 2600.ms,
                delay: 1400.ms,
                color: const Color(0xFFE9B84A),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
