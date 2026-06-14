import { teamDisplayName } from '../lib/teams';
import { useLang } from '../i18n';

/** Home × Away line — always LTR so names line up with the flags (home left, away right). */
export function TeamMatchup({
  homeCode,
  homeAr,
  homeEn,
  awayCode,
  awayAr,
  awayEn,
  className = '',
}: {
  homeCode: string;
  homeAr: string;
  homeEn: string | null | undefined;
  awayCode: string;
  awayAr: string;
  awayEn: string | null | undefined;
  className?: string;
}) {
  const lang = useLang();
  const home = teamDisplayName(homeCode, homeAr, homeEn, lang);
  const away = teamDisplayName(awayCode, awayAr, awayEn, lang);

  return (
    <div dir="ltr" className={className}>
      <bdi dir="ltr">{home}</bdi>
      <span className="opacity-50 px-1">×</span>
      <bdi dir="ltr">{away}</bdi>
    </div>
  );
}
