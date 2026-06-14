import { C } from '../lib/theme';
import { t } from '../i18n';

/** Glassmorphism "how points work" card — ported from Flutter ScoringRulesCard. */
export function ScoringRulesCard() {
  return (
    <section className="glass rounded-[18px] px-3.5 py-3">
      <header className="flex items-center gap-2 mb-2.5">
        <span style={{ color: C.pitchGreen }}>🏆</span>
        <h3 className="font-extrabold" style={{ color: C.pitchGreen, fontSize: 15 }}>
          {t('howPoints')}
        </h3>
      </header>

      <Rule icon="✓" color={C.pitchGreen} bold text={t('exact3')} />
      <Rule icon="👍" color="#9CCC65" text={t('correct1')} />
      <Rule icon="✗" color="#9AA0A6" text={t('wrong0')} />

      <div className="my-2.5 border-t border-white/15" />

      <Rule icon="🔥" color={C.arabBadgeOrange} bold text={t('saudiDouble')} />
      <Rule icon="🔒" color="#9AA0A6" text={t('lockHint')} />
    </section>
  );
}

function Rule({
  icon, color, text, bold,
}: { icon: string; color: string; text: string; bold?: boolean }) {
  return (
    <div className="flex items-start gap-2 mb-1.5">
      <span style={{ color, fontSize: 13, lineHeight: '18px' }}>{icon}</span>
      <span
        className="text-[13px] leading-[18px]"
        style={{ color: bold ? color : 'rgba(255,255,255,0.82)', fontWeight: bold ? 700 : 400 }}
      >
        {text}
      </span>
    </div>
  );
}
