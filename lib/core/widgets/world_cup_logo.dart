import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/widgets/optional_image.dart';

/// Paths bundled under [assets/images/].
const kWorldCupScorebugLogo = 'assets/images/wc26_logo.png';
const kWorldCupAuthLogo = 'assets/images/fifa-world-cup-2026--white.png';

/// FIFA World Cup 26 logo — auth screen and match scorebug.
class WorldCupLogo extends StatelessWidget {
  const WorldCupLogo({
    super.key,
    this.height = 120,
    this.showFallbackFrame = false,
    this.assetPath = kWorldCupScorebugLogo,
  });

  final double height;
  final bool showFallbackFrame;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final image = OptionalImage(
      path: assetPath,
      fit: BoxFit.contain,
      cacheHeight: (height * 2).round(),
      fallback: _WorldCupLogoFallback(compact: height < 80),
    );

    if (!showFallbackFrame) {
      return SizedBox(height: height, child: image);
    }

    return Container(
      height: height,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: image,
    );
  }
}

class _WorldCupLogoFallback extends StatelessWidget {
  const _WorldCupLogoFallback({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.emoji_events,
          color: AppTheme.accentGold,
          size: compact ? 18 : 40,
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          const Text(
            '26',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}
