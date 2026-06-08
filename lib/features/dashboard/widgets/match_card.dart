import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:world_cup_predictor/core/constants/teams.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/utils/prediction_window.dart';
import 'package:world_cup_predictor/core/widgets/world_cup_logo.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/prediction.dart';

const _maxScore = 30;

class MatchCard extends StatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.prediction,
    required this.onSave,
    this.onViewPredictions,
  });

  final Match match;
  final Prediction? prediction;
  final Future<void> Function(int home, int away) onSave;
  final VoidCallback? onViewPredictions;

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late int _home;
  late int _away;
  Timer? _timer;
  Timer? _savedTimer;
  bool _saving = false;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    _home = widget.prediction?.homeScore ?? 0;
    _away = widget.prediction?.awayScore ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prediction?.id != widget.prediction?.id) {
      _home = widget.prediction?.homeScore ?? 0;
      _away = widget.prediction?.awayScore ?? 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _savedTimer?.cancel();
    super.dispose();
  }

  bool get _hasPrediction => widget.prediction != null;

  bool get _dirty {
    final p = widget.prediction;
    if (p == null) return true;
    return _home != p.homeScore || _away != p.awayScore;
  }

  String _buttonLabel(S s) {
    if (_justSaved) return s.justSaved;
    if (!_hasPrediction) return s.saveNew;
    return _dirty ? s.saveEdit : s.saved;
  }

  IconData get _buttonIcon {
    if (_justSaved) return Icons.check_circle;
    if (!_hasPrediction) return Icons.check;
    return _dirty ? Icons.edit : Icons.check_circle_outline;
  }

  Future<void> _submit() async {
    final s = S.of(context);
    setState(() => _saving = true);
    try {
      await widget.onSave(_home, _away);
      if (mounted) {
        _savedTimer?.cancel();
        setState(() => _justSaved = true);
        _savedTimer = Timer(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _justSaved = false);
        });
      }
    } catch (e) {
      debugPrint('savePrediction failed: $e');
      if (mounted) {
        final raw = e.toString().toLowerCase();
        final msg = raw.contains('window closed')
            ? s.errWindow
            : (raw.contains('row-level security') || raw.contains('violates'))
                ? s.errRls
                : s.errGeneric;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final match = widget.match;
    final open = isPredictionOpen(match.kickoffAt);

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScoreBug(
              home: home,
              away: away,
              homeScore: _home,
              awayScore: _away,
              open: open,
              isSaudi: match.isSaudiMatch,
              kickoff: match.kickoffAt,
              onHome: (v) => setState(() => _home = v),
              onAway: (v) => setState(() => _away = v),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    s.ar
                        ? '${home.nameAr}  ×  ${away.nameAr}'
                        : '${home.nameEn}  ×  ${away.nameEn}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  _formatKickoff(match.kickoffAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (widget.onViewPredictions != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onViewPredictions,
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: Text(s.viewPredictions),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.pitchGreen,
                  side: BorderSide(
                    color: AppTheme.pitchGreen.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
            if (open) ...[
              const SizedBox(height: 12),
              _StatusLine(
                justSaved: _justSaved,
                hasPrediction: _hasPrediction,
                dirty: _dirty,
              ),
              const SizedBox(height: 10),
              _buildSaveButton(),
            ] else ...[
              const SizedBox(height: 12),
              _ClosedSummary(match: match, prediction: widget.prediction),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final s = S.of(context);
    final enabled = _dirty && !_saving;
    Widget button = FilledButton.icon(
      onPressed: enabled ? _submit : null,
      style: _justSaved
          ? FilledButton.styleFrom(
              backgroundColor: AppTheme.pitchGreen,
              foregroundColor: Colors.black,
            )
          : null,
      icon: _saving
          ? const SizedBox(
              height: 18,
              width: 18,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(_buttonIcon),
      label: Text(_buttonLabel(s)),
    );

    if (_justSaved) {
      button = button
          .animate(key: const ValueKey('saved-pulse'))
          .scaleXY(begin: 0.92, end: 1, duration: 320.ms, curve: Curves.easeOut)
          .shimmer(duration: 900.ms, color: Colors.white54);
    }
    return button;
  }

  String _formatKickoff(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} — $h:$m';
  }
}

// ─────────────────────────────────────────────────────────────
// Broadcast-style scorebug (FIFA 2026 look)
// ─────────────────────────────────────────────────────────────
class _ScoreBug extends StatelessWidget {
  const _ScoreBug({
    required this.home,
    required this.away,
    required this.homeScore,
    required this.awayScore,
    required this.open,
    required this.isSaudi,
    required this.kickoff,
    required this.onHome,
    required this.onAway,
  });

  final TeamInfo home;
  final TeamInfo away;
  final int homeScore;
  final int awayScore;
  final bool open;
  final bool isSaudi;
  final DateTime kickoff;
  final ValueChanged<int> onHome;
  final ValueChanged<int> onAway;

  static const _scoreBg = Color(0xFF0E2A1E);
  static const _codeBg = Color(0xFF0C0C0C);

  @override
  Widget build(BuildContext context) {
    // Force LTR so the bug always reads home → away like a TV broadcast.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: _jerseyColor(home)),
                    Expanded(child: _codePanel(_code3(home))),
                    _flag(home),
                    _scoreCell(homeScore, onHome, 'h'),
                    const _Wc26Badge(),
                    _scoreCell(awayScore, onAway, 'a'),
                    _flag(away),
                    Expanded(child: _codePanel(_code3(away))),
                    Container(width: 5, color: _jerseyColor(away)),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ClockTab(kickoff: kickoff, open: open),
                if (isSaudi) ...[
                  const SizedBox(width: 8),
                  const _DoubleBadge(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codePanel(String code) => Container(
        color: _codeBg,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            code,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );

  Widget _flag(TeamInfo t) => Container(
        width: 52,
        color: _codeBg,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
        alignment: Alignment.center,
        child: t.flagUrl.isEmpty
            ? const Icon(Icons.flag, color: Colors.white24, size: 18)
            : ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CachedNetworkImage(
                  imageUrl: t.flagUrl,
                  fit: BoxFit.contain,
                ),
              ),
      );

  Widget _scoreCell(int value, ValueChanged<int> onChanged, String tag) {
    final number = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 30,
            height: 1,
          ),
        ),
      ),
    ).animate(key: ValueKey('$tag$value')).scaleXY(
        begin: 1.35, end: 1, duration: 200.ms, curve: Curves.easeOut);

    return Container(
      width: 56,
      color: _scoreBg,
      child: open
          ? Column(
              children: [
                _chevron(Icons.keyboard_arrow_up_rounded,
                    value < _maxScore ? () => onChanged(value + 1) : null),
                Expanded(child: number),
                _chevron(Icons.keyboard_arrow_down_rounded,
                    value > 0 ? () => onChanged(value - 1) : null),
              ],
            )
          : number,
    );
  }

  Widget _chevron(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 20,
          child: Icon(icon,
              size: 18, color: onTap == null ? Colors.white24 : Colors.white),
        ),
      );
}

/// Center World Cup logo. Uses assets/images/wc26_logo.png when present,
/// otherwise falls back to a simple trophy + 26 mark.
class _Wc26Badge extends StatelessWidget {
  const _Wc26Badge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 54,
      child: WorldCupLogo(height: 58, showFallbackFrame: true),
    );
  }
}

/// The green clock tab hanging under the bug — shows the live countdown.
class _ClockTab extends StatelessWidget {
  const _ClockTab({required this.kickoff, required this.open});

  final DateTime kickoff;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!open) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          color: Color(0xFFB3261E),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(s.closed,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ],
        ),
      );
    }

    final d = timeUntilPredictionCloses(kickoff);
    final days = d.inDays;
    final hh = d.inHours.remainder(24).toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    const numStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 17,
      letterSpacing: 1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0E9F5B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      // Separate widgets (not one bidi string) so "3 يوم 22:09:00" reads right.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          if (days > 0) ...[
            Text('$days', style: numStyle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(s.dayUnit,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
          Text('$hh:$mm:$ss', style: numStyle),
        ],
      ),
    );
  }
}

/// Shows whether the current prediction is saved / has unsaved changes.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.justSaved,
    required this.hasPrediction,
    required this.dirty,
  });

  final bool justSaved;
  final bool hasPrediction;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (justSaved) {
      return _pill(
        context,
        icon: Icons.check_circle,
        text: s.statusJustSaved,
        color: AppTheme.pitchGreen,
      ).animate(key: const ValueKey('saved-banner')).fadeIn(duration: 250.ms).slideY(begin: 0.3, end: 0);
    }
    if (hasPrediction && dirty) {
      return _pill(
        context,
        icon: Icons.edit_note,
        text: s.statusUnsaved,
        color: AppTheme.accentGold,
      );
    }
    if (hasPrediction && !dirty) {
      return _pill(
        context,
        icon: Icons.verified,
        text: s.statusSaved,
        color: AppTheme.pitchGreen,
      );
    }
    return const SizedBox(height: 4);
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String text, required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DoubleBadge extends StatelessWidget {
  const _DoubleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Text(
        S.of(context).doubleBadge,
        style: const TextStyle(
          color: AppTheme.arabBadgeOrange,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ClosedSummary extends StatelessWidget {
  const _ClosedSummary({required this.match, required this.prediction});

  final Match match;
  final Prediction? prediction;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        if (match.isFinished && match.homeScore != null)
          _ResultChip(
            label: s.result,
            value: '${match.homeScore} : ${match.awayScore}',
            color: AppTheme.accentGold,
          ),
        if (prediction != null) ...[
          const SizedBox(height: 8),
          _ResultChip(
            label: s.yourPick,
            value: '${prediction!.homeScore} : ${prediction!.awayScore}',
            color: AppTheme.pitchGreen,
          ),
        ] else
          Text(
            s.notPredicted,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (match.isFinished && prediction?.pointsEarned != null) ...[
          const SizedBox(height: 10),
          Text(
            s.points(prediction!.pointsEarned!),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
String _code3(TeamInfo t) {
  final letters = t.nameEn.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (letters.length >= 3) return letters.substring(0, 3).toUpperCase();
  if (letters.isNotEmpty) return letters.toUpperCase();
  return t.code.toUpperCase();
}

const _jerseyPalette = <Color>[
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFDD835), // yellow
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFF3949AB), // indigo
];

Color _jerseyColor(TeamInfo t) =>
    _jerseyPalette[t.code.hashCode.abs() % _jerseyPalette.length];
