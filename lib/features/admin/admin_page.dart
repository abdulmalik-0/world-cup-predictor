import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:world_cup_predictor/core/constants/teams.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(allMatchesProvider);
    ref.invalidate(upcomingMatchesProvider);
    ref.invalidate(finishedMatchesProvider);
    ref.invalidate(leaderboardProvider);
    ref.invalidate(myStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final s = S.of(context);

    return Directionality(
      textDirection: s.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.adminPanel),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final added = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const _AddMatchSheet(),
                  );
                  if (added == true) _refresh(ref);
                },
                icon: const Icon(Icons.add),
                label: Text(s.addMatch),
              )
            : null,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: !isAdmin
                ? const _NoAccess()
                : ref.watch(allMatchesProvider).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('خطأ: $e')),
                    data: (matches) {
                      if (matches.isEmpty) {
                        return Center(child: Text(s.noMatchesAdmin));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: matches.length,
                        itemBuilder: (_, i) => _AdminMatchTile(
                            match: matches[i], onChanged: () => _refresh(ref)),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(S.of(context).adminOnly),
        ],
      ),
    );
  }
}

class _AdminMatchTile extends ConsumerWidget {
  const _AdminMatchTile({required this.match, required this.onChanged});

  final Match match;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final df = DateFormat('d/M HH:mm');
    final service = ref.read(matchServiceProvider);
    final s = S.of(context);
    final names = s.ar
        ? '${home.nameAr} × ${away.nameAr}'
        : '${home.nameEn} × ${away.nameEn}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          names,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${df.format(match.kickoffAt)} • ${_statusLabel(match, s)}'
          '${match.homeScore != null ? ' • ${match.homeScore}-${match.awayScore}' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'result':
                {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => _ResultDialog(match: match),
                  );
                  if (ok == true) onChanged();
                }
              case 'delete':
                {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(s.deleteMatchQ),
                      content: Text(names),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(s.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(s.delete),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await service.deleteMatch(match.id);
                    onChanged();
                  }
                }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'result', child: Text(s.enterResult)),
            PopupMenuItem(value: 'delete', child: Text(s.delete)),
          ],
        ),
      ),
    );
  }

  String _statusLabel(Match m, S s) => switch (m.status) {
        MatchStatus.scheduled => s.statusScheduled,
        MatchStatus.live => s.statusLive,
        MatchStatus.finished => s.statusFinished,
        MatchStatus.cancelled => s.statusCancelled,
      };
}

class _ResultDialog extends ConsumerStatefulWidget {
  const _ResultDialog({required this.match});

  final Match match;

  @override
  ConsumerState<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends ConsumerState<_ResultDialog> {
  late int _home = widget.match.homeScore ?? 0;
  late int _away = widget.match.awayScore ?? 0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final home = resolveTeam(
      code: widget.match.homeTeamCode,
      nameAr: widget.match.homeTeam,
      nameEn: widget.match.homeTeamEn,
    );
    final away = resolveTeam(
      code: widget.match.awayTeamCode,
      nameAr: widget.match.awayTeam,
      nameEn: widget.match.awayTeamEn,
    );

    final s = S.of(context);
    return AlertDialog(
      title: Text(s.enterResult),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.ar
              ? '${home.nameAr} × ${away.nameAr}'
              : '${home.nameEn} × ${away.nameEn}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStepper(
                value: _home,
                onChanged: (v) => setState(() => _home = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(':', style: TextStyle(fontSize: 24)),
              ),
              _MiniStepper(
                value: _away,
                onChanged: (v) => setState(() => _away = v),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await ref.read(matchServiceProvider).setMatchResult(
                          matchId: widget.match.id,
                          homeScore: _home,
                          awayScore: _away,
                        );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (context.mounted) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.errSaveResult)),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(s.saveResult),
        ),
      ],
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _AddMatchSheet extends ConsumerStatefulWidget {
  const _AddMatchSheet();

  @override
  ConsumerState<_AddMatchSheet> createState() => _AddMatchSheetState();
}

class _AddMatchSheetState extends ConsumerState<_AddMatchSheet> {
  TeamInfo? _home;
  TeamInfo? _away;
  DateTime? _kickoff;
  final _externalRef = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _externalRef.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _kickoff ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_kickoff ?? now),
    );
    if (time == null) return;
    setState(() {
      _kickoff =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_home == null || _away == null || _kickoff == null) {
      setState(() => _error = s.pickBothTeams);
      return;
    }
    if (_home!.code == _away!.code) {
      setState(() => _error = s.sameTeam);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(matchServiceProvider).createMatch(
            homeTeam: _home!.nameAr,
            homeTeamCode: _home!.code,
            homeTeamEn: _home!.nameEn,
            awayTeam: _away!.nameAr,
            awayTeamCode: _away!.code,
            awayTeamEn: _away!.nameEn,
            kickoffAt: _kickoff!,
            externalRef: _externalRef.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = S.of(context).errAddMatch;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = allTeams();
    final s = S.of(context);
    final df = DateFormat('EEEE d/M • HH:mm', s.ar ? 'ar' : 'en');

    return Directionality(
      textDirection: s.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.addMatch,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _teamDropdown(
                label: s.homeTeam,
                value: _home,
                teams: teams,
                onSelected: (t) => setState(() => _home = t),
              ),
              const SizedBox(height: 12),
              _teamDropdown(
                label: s.awayTeam,
                value: _away,
                teams: teams,
                onSelected: (t) => setState(() => _away = t),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.event),
                label: Text(
                  _kickoff == null ? s.pickKickoff : df.format(_kickoff!),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _externalRef,
                decoration: InputDecoration(
                  labelText: s.apiId,
                  hintText: '537020',
                  prefixIcon: const Icon(Icons.sync),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(s.addMatch),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamDropdown({
    required String label,
    required TeamInfo? value,
    required List<TeamInfo> teams,
    required ValueChanged<TeamInfo> onSelected,
  }) {
    return DropdownMenu<TeamInfo>(
      initialSelection: value,
      enableFilter: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      leadingIcon: const Icon(Icons.flag_outlined),
      menuHeight: 320,
      onSelected: (t) {
        if (t != null) onSelected(t);
      },
      dropdownMenuEntries: [
        for (final t in teams)
          DropdownMenuEntry(value: t, label: '${t.nameAr} (${t.code})'),
      ],
    );
  }
}
