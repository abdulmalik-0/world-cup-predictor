import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { Match } from '../api/types';
import { matchesApi } from '../api/matches';
import { C } from '../lib/theme';
import { flagUrl, teamDisplayName } from '../lib/teams';
import { useLang } from '../i18n';
import { hex } from '../components/CountdownBox';
import { PredictionsModal } from '../components/PredictionsModal';
import { t } from '../i18n';

/**
 * Past Matches — finished games. Tap any match to open the votes sheet
 * (everyone's predictions + points are revealed once a match is over).
 */
export function PastMatches() {
  const [openMatch, setOpenMatch] = useState<Match | null>(null);
  const q = useQuery({ queryKey: ['finished'], queryFn: matchesApi.finished });
  const matches = q.data ?? [];

  return (
    <main className="pt-[86px] pb-20 px-4">
      <div className="mx-auto w-full max-w-[680px]">
        <header className="flex items-center gap-3 mb-1">
          <span className="text-3xl">📜</span>
          <h1 className="text-2xl font-extrabold">{t('pastMatches')}</h1>
        </header>
        <p className="text-[13px] text-white/55 mb-5">{t('tapToSeeVotes')}</p>

        {q.isLoading && <p className="text-white/60">{t('loading')}</p>}
        {!q.isLoading && matches.length === 0 && <p className="text-white/55">{t('noFinished')}</p>}

        <div className="space-y-3">
          {matches.map((m) => (
            <FinishedRow key={m.id} match={m} onClick={() => setOpenMatch(m)} />
          ))}
        </div>
      </div>

      {openMatch && <PredictionsModal match={openMatch} onClose={() => setOpenMatch(null)} />}
    </main>
  );
}

function FinishedRow({ match, onClick }: { match: Match; onClick: () => void }) {
  const lang = useLang();
  const home = teamDisplayName(match.homeTeamCode, match.homeTeam, match.homeTeamEn, lang);
  const away = teamDisplayName(match.awayTeamCode, match.awayTeam, match.awayTeamEn, lang);
  return (
    <button
      onClick={onClick}
      className="glass rounded-2xl w-full p-3.5 flex items-center gap-3 text-start hover:brightness-110 transition"
    >
      <Side code={match.homeTeamCode} name={home} align="start" />

      <div className="shrink-0 text-center px-2" dir="ltr">
        <div className="font-black text-xl leading-none tabular-nums">
          {match.homeScore ?? '–'} : {match.awayScore ?? '–'}
        </div>
        <div className="text-[10px] uppercase tracking-wide mt-1" style={{ color: C.accentGold }}>
          {t('finalResult')}
        </div>
      </div>

      <Side code={match.awayTeamCode} name={away} align="end" />

      <span className="shrink-0 ms-1" style={{ color: hex(C.pitchGreen, 1) }}>👥</span>
    </button>
  );
}

function Side({ code, name, align }: { code: string; name: string; align: 'start' | 'end' }) {
  const url = flagUrl(code);
  return (
    <div className={`flex-1 min-w-0 flex items-center gap-2 ${align === 'end' ? 'flex-row-reverse text-end' : ''}`}>
      {url && <img src={url} alt={code} className="h-6 w-9 object-cover rounded-sm shrink-0" />}
      <span className="font-bold text-[14px] truncate">{name}</span>
    </div>
  );
}
