import 'dart:io';

import 'match_rows.dart';

void main() {
  final buffer = StringBuffer('''
-- كأس العالم 2026 — دور المجموعات (72 مباراة)
-- التوقيت: بتوقيت السعودية (+03)
-- Generated — do not edit by hand

TRUNCATE public.prediction_history, public.predictions, public.matches CASCADE;

INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
''');

  for (var i = 0; i < groupMatches.length; i++) {
    final m = groupMatches[i];
    final comma = i < groupMatches.length - 1 ? ',' : ';';
    buffer.writeln(
      "  ('${m.homeAr}', '${m.homeEn}', '${m.awayAr}', '${m.awayEn}', "
      "'${m.homeCode}', '${m.awayCode}', '${m.kickoff}', 'scheduled')$comma",
    );
  }

  buffer.writeln('''
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('نصف نهائي 1', 'Semi-Final 1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-14 22:00:00+03', 'scheduled'),
  ('نصف نهائي 2', 'Semi-Final 2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-15 22:00:00+03', 'scheduled'),
  ('تحديد المركز الثالث', 'Third Place', 'TBD', 'TBD', 'XX', 'YY', '2026-07-18 23:00:00+03', 'scheduled'),
  ('النهائي', 'Final', 'TBD', 'TBD', 'XX', 'YY', '2026-07-19 22:00:00+03', 'scheduled');
''');

  File('../supabase/seed.sql').writeAsStringSync(buffer.toString());
  print('Wrote supabase/seed.sql (${groupMatches.length + 4} matches)');
}
