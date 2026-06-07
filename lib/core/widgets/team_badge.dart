import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/constants/teams.dart';
import 'package:world_cup_predictor/models/match.dart';

class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.team,
    this.alignEnd = false,
    this.compact = false,
  });

  final TeamInfo team;
  final bool alignEnd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final crossAlign =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    if (compact) {
      return Column(
        crossAxisAlignment: crossAlign,
        children: [
          _FlagImage(team: team, size: 28),
          const SizedBox(height: 6),
          _TeamNames(team: team, alignEnd: alignEnd, compact: true),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (alignEnd) Expanded(child: _TeamNames(team: team, alignEnd: true)),
        if (alignEnd) const SizedBox(width: 8),
        _FlagImage(team: team, size: 36),
        if (!alignEnd) const SizedBox(width: 8),
        if (!alignEnd) Expanded(child: _TeamNames(team: team, alignEnd: false)),
      ],
    );
  }
}

class _FlagImage extends StatelessWidget {
  const _FlagImage({required this.team, required this.size});

  final TeamInfo team;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (team.flagUrl.isEmpty) {
      return Container(
        width: size * 1.35,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(Icons.sports_soccer, size: size * 0.55),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: team.flagUrl,
        width: size * 1.35,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: size * 1.35,
          height: size,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size * 1.35,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.flag_outlined, size: size * 0.5),
        ),
      ),
    );
  }
}

class _TeamNames extends StatelessWidget {
  const _TeamNames({
    required this.team,
    required this.alignEnd,
    required this.compact,
  });

  final TeamInfo team;
  final bool alignEnd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
          Text(
            team.nameAr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 14 : null,
                ),
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            team.nameEn,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: compact ? 11 : 12,
                ),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
  }
}
class MatchTeamsHeader extends StatelessWidget {
  const MatchTeamsHeader({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final home = resolveTeam(
      code: match.homeTeamCode,
      nameAr: match.homeTeam,
      nameEn: match.homeTeamEn,
    );
    final away = resolveTeam(
      code: match.awayTeamCode,
      nameAr: match.awayTeam,
      nameEn: match.awayTeamEn,
    );

    return Row(
      children: [
        Expanded(child: TeamBadge(team: home, compact: true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '×',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(child: TeamBadge(team: away, alignEnd: true, compact: true)),
      ],
    );
  }
}
