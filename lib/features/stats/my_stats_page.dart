import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_cup_predictor/core/constants/teams.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/models/my_stats.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class MyStatsPage extends ConsumerWidget {
  const MyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myStatsProvider),
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (stats) {
          final s = S.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                s.myStats,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              _StatGrid(stats: stats),
              const SizedBox(height: 24),
              if (stats.finishedEntries.length >= 2) ...[
                Text(
                  s.pointsProgress,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    child: SizedBox(
                      height: 160,
                      child: CustomPaint(
                        painter: _PointsChartPainter(
                          points: stats.finishedEntries
                              .map((e) => e.cumulativePoints.toDouble())
                              .toList(),
                          color: AppTheme.pitchGreen,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                s.myHistory,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (stats.finishedEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(s.noFinished),
                  ),
                )
              else
                ...stats.finishedEntries.reversed.map(
                  (e) => _HistoryTile(entry: e),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final MyStats stats;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final accuracy = (stats.accuracy * 100).round();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          icon: Icons.stars_rounded,
          label: s.totalPoints,
          value: '${stats.totalPoints}',
          color: AppTheme.accentGold,
        ),
        _StatCard(
          icon: Icons.checklist_rtl_rounded,
          label: s.predictionsCount,
          value: '${stats.predictionsMade}',
          color: AppTheme.pitchGreen,
        ),
        _StatCard(
          icon: Icons.percent_rounded,
          label: s.accuracy,
          value: s.ar ? '$accuracy٪' : '$accuracy%',
          color: AppTheme.primaryGreen,
        ),
        _StatCard(
          icon: Icons.gps_fixed_rounded,
          label: s.correctPredictions,
          value: '${stats.exactHits}',
          color: AppTheme.arabBadgeOrange,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final StatEntry entry;

  @override
  Widget build(BuildContext context) {
    final m = entry.match;
    final home = resolveTeam(
      code: m.homeTeamCode,
      nameAr: m.homeTeam,
      nameEn: m.homeTeamEn,
    );
    final away = resolveTeam(
      code: m.awayTeamCode,
      nameAr: m.awayTeam,
      nameEn: m.awayTeamEn,
    );
    final s = S.of(context);
    final points = entry.prediction.pointsEarned ?? 0;
    final (badgeColor, badgeText) = entry.isExact
        ? (AppTheme.accentGold, s.exactBadge)
        : entry.isCorrectOutcome
            ? (AppTheme.pitchGreen, s.correctBadge)
            : (Colors.redAccent, s.wrongBadge);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.ar
                        ? '${home.nameAr} × ${away.nameAr}'
                        : '${home.nameEn} × ${away.nameEn}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.result} ${m.homeScore}-${m.awayScore} • ${s.yourPick} '
                    '${entry.prediction.homeScore}-${entry.prediction.awayScore}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  '+$points',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: points > 0
                            ? AppTheme.accentGold
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(s.pts, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsChartPainter extends CustomPainter {
  _PointsChartPainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxY = points.last == 0 ? 1.0 : points.last.toDouble();
    final dx = size.width / (points.length - 1);

    Offset pointAt(int i) {
      final x = dx * i;
      final y = size.height - (points[i] / maxY) * size.height;
      return Offset(x, y);
    }

    // Gridlines
    final grid = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Area fill
    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i < points.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );

    // Line
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(linePath, line);

    // Last dot
    canvas.drawCircle(pointAt(points.length - 1), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PointsChartPainter old) =>
      old.points != points || old.color != color;
}
