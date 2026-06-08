import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';

/// Explains how prediction points are calculated.
class ScoringRulesCard extends StatelessWidget {
  const ScoringRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final body =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70);
    final bold =
        body?.copyWith(fontWeight: FontWeight.w700, color: Colors.white);

    // Split the Saudi rule into a title and the points detail (next line).
    final rawSaudi = s.scoringRulesSaudi;
    final colon = rawSaudi.indexOf(':');
    final saudiTitle = (colon >= 0 ? rawSaudi.substring(0, colon) : rawSaudi)
        .replaceAll('🔥', '')
        .trim();
    final saudiDetail = colon >= 0 ? rawSaudi.substring(colon + 1).trim() : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xA60E2E1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.pitchGreen.withValues(alpha: 0.30)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 20, color: AppTheme.accentGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.scoringRulesTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RuleRow(
            icon: Icons.check_circle,
            color: AppTheme.pitchGreen,
            text: s.scoringRulesExact,
            style: bold,
          ),
          _RuleRow(
            icon: Icons.thumb_up,
            color: Colors.lightGreenAccent.shade400,
            text: s.scoringRulesWinner,
            style: body,
          ),
          _RuleRow(
            icon: Icons.cancel,
            color: Colors.grey.shade400,
            text: s.scoringRulesWrong,
            style: body,
          ),
          const SizedBox(height: 8),
          // Saudi double — title on the first line, points detail below it.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            decoration: BoxDecoration(
              color: AppTheme.arabBadgeOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.arabBadgeOrange.withValues(alpha: 0.55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: AppTheme.arabBadgeOrange, size: 19),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        saudiTitle,
                        style: bold?.copyWith(
                          color: const Color(0xFFFFC58A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...saudiDetail.split(RegExp(r'[،,]')).map(
                      (part) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          part.trim(),
                          style: bold?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _RuleRow(
            icon: Icons.lock_clock,
            color: Colors.white54,
            text: s.scoringRulesLock,
            style: body?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.color,
    required this.text,
    this.style,
  });

  final IconData icon;
  final Color color;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
