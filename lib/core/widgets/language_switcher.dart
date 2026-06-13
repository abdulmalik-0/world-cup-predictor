import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';

/// Small CIRCULAR language toggle for the app bar (Eng / عربي).
class LanguageSwitcherChip extends ConsumerWidget {
  const LanguageSwitcherChip({super.key, this.size = 32});

  /// Diameter of the circle.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Material(
      shape: const CircleBorder(),
      color: Colors.black.withValues(alpha: 0.40),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(localeProvider.notifier).toggle(),
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.pitchGreen.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            s.switchLanguageLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              height: 1.0,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
