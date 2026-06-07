import 'dart:async';

import 'package:flutter/material.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/utils/prediction_window.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/prediction.dart';

class MatchCard extends StatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.prediction,
    required this.onSave,
  });

  final Match match;
  final Prediction? prediction;
  final Future<void> Function(int home, int away) onSave;

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  Timer? _timer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(
      text: widget.prediction?.homeScore.toString() ?? '',
    );
    _awayController = TextEditingController(
      text: widget.prediction?.awayScore.toString() ?? '',
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prediction?.id != widget.prediction?.id) {
      _homeController.text = widget.prediction?.homeScore.toString() ?? '';
      _awayController.text = widget.prediction?.awayScore.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final home = int.tryParse(_homeController.text.trim());
    final away = int.tryParse(_awayController.text.trim());
    if (home == null || away == null || home < 0 || away < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل نتيجة صحيحة (أرقام ≥ 0)')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(home, away);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.prediction == null ? 'تم حفظ التوقع' : 'تم تعديل التوقع',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتهى وقت التوقع أو حدث خطأ')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final open = isPredictionOpen(match.kickoffAt);
    final countdown = timeUntilPredictionCloses(match.kickoffAt);
    final hasPrediction = widget.prediction != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (match.isArabTeamMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.arabBadgeOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.arabBadgeOrange),
                    ),
                    child: const Text(
                      'دبل 🔥',
                      style: TextStyle(
                        color: AppTheme.arabBadgeOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(
                  open ? Icons.timer_outlined : Icons.lock_outline,
                  size: 16,
                  color: open ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  open ? 'يُغلق خلال ${formatCountdown(countdown)}' : 'التوقعات مغلقة',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TeamColumn(name: match.homeTeam, code: match.homeTeamCode),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                  ),
                ),
                Expanded(
                  child: _TeamColumn(
                    name: match.awayTeam,
                    code: match.awayTeamCode,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatKickoff(match.kickoffAt),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (open) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _homeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('-', style: TextStyle(fontSize: 24)),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _awayController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(hasPrediction ? 'تعديل التوقع' : 'حفظ التوقع'),
              ),
            ] else if (hasPrediction) ...[
              const SizedBox(height: 12),
              Text(
                'توقعك: ${widget.prediction!.homeScore}-${widget.prediction!.awayScore}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
            if (match.isFinished && widget.prediction?.pointsEarned != null) ...[
              const SizedBox(height: 8),
              Text(
                'نقاطك: ${widget.prediction!.pointsEarned}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatKickoff(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} — ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.name,
    required this.code,
    this.alignEnd = false,
  });

  final String name;
  final String code;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        ),
        Text(
          code,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
