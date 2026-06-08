import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';

/// Explains how prediction points are calculated.
class ScoringRulesCard extends StatelessWidget {
  const ScoringRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final body = Theme.of(context).textTheme.bodySmall;
    final bold = body?.copyWith(fontWeight: FontWeight.w700);

    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    size: 20, color: AppTheme.pitchGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.scoringRulesTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pitchGreen,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _RuleRow(
              icon: Icons.check_circle_outline,
              color: AppTheme.pitchGreen,
              text: s.scoringRulesExact,
              style: bold,
            ),
            _RuleRow(
              icon: Icons.thumb_up_outlined,
              color: Colors.lightGreenAccent.shade400,
              text: s.scoringRulesWinner,
              style: body,
            ),
            _RuleRow(
              icon: Icons.close,
              color: Colors.grey,
              text: s.scoringRulesWrong,
              style: body,
            ),
            const Divider(height: 20),
            _RuleRow(
              icon: Icons.local_fire_department,
              color: AppTheme.arabBadgeOrange,
              text: s.scoringRulesSaudi,
              style: bold?.copyWith(color: AppTheme.arabBadgeOrange),
            ),
            const SizedBox(height: 4),
            _RuleRow(
              icon: Icons.lock_clock,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              text: s.scoringRulesLock,
              style: body,
            ),
          ],
        ),
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
