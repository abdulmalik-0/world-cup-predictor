import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:world_cup_predictor/core/widgets/invenu_logo.dart';
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
        // ENTERGAME wordmark + "World Cup Arena" on its own line below.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InvenuLogo(height: 56),
              const SizedBox(height: 12),
              Text(
                'World Cup Arena',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
              ),
            ],
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
