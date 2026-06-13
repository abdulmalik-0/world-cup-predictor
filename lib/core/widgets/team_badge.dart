import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/constants/teams.dart';
import 'package:world_cup_predictor/models/match.dart';

/// A country flag rendered as a rounded card with a soft border + shadow.
class FlagAvatar extends StatelessWidget {
  const FlagAvatar({super.key, required this.team, this.size = 44});

  final TeamInfo team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final width = size * 1.4;
    final border = Theme.of(context).colorScheme.outline.withValues(alpha: 0.25);

    final child = team.flagUrl.isEmpty
        ? Container(
            width: width,
            height: size,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.sports_soccer, size: size * 0.55),
          )
        : CachedNetworkImage(
            imageUrl: team.flagUrl,
            width: width,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: width,
              height: size,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (_, __, ___) => Container(
              width: width,
              height: size,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.flag_outlined, size: size * 0.5),
            ),
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: child,
      ),
    );
  }
}

/// Flag + names. [compact] stacks them vertically and centered (match cards);
/// otherwise they sit in a row.
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
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlagAvatar(team: team, size: 46),
          const SizedBox(height: 10),
          _TeamNames(team: team, center: true, compact: true),
        ],
      );
    }

    final names = Expanded(
      child: _TeamNames(team: team, center: false, compact: false, alignEnd: alignEnd),
    );
    return Row(
      children: [
        if (alignEnd) names,
        if (alignEnd) const SizedBox(width: 8),
        FlagAvatar(team: team, size: 34),
        if (!alignEnd) const SizedBox(width: 8),
        if (!alignEnd) names,
      ],
    );
  }
}

class _TeamNames extends StatelessWidget {
  const _TeamNames({
    required this.team,
    required this.center,
    required this.compact,
    this.alignEnd = false,
  });

  final TeamInfo team;
  final bool center;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cross = center
        ? CrossAxisAlignment.center
        : (alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start);
    final textAlign = center
        ? TextAlign.center
        : (alignEnd ? TextAlign.end : TextAlign.start);

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          team.nameAr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 15 : null,
                height: 1.1,
              ),
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
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
        Expanded(child: TeamBadge(team: away, compact: true)),
      ],
    );
  }
}
