import { C } from '../lib/theme';

/** Glassmorphism "how points work" card — ported from Flutter ScoringRulesCard. */
export function ScoringRulesCard() {
  return (
    <section className="glass rounded-[18px] px-3.5 py-3">
      <header className="flex items-center gap-2 mb-2.5">
        <span style={{ color: C.pitchGreen }}>🏆</span>
        <h3 className="font-extrabold" style={{ color: C.pitchGreen, fontSize: 15 }}>
          How points work
        </h3>
      </header>

      <Rule icon="✓" color={C.pitchGreen} bold text="Exact score = 3 points" />
      <Rule icon="👍" color="#9CCC65" text="Correct winner or draw = 1 point" />
      <Rule icon="✗" color="#9AA0A6" text="Wrong pick = 0" />

      <div className="my-2.5 border-t border-white/15" />

      <Rule icon="🔥" color={C.arabBadgeOrange} bold text="Saudi Arabia matches = double points" />
      <Rule icon="🔒" color="#9AA0A6" text="Predictions lock 1 hour before kickoff" />
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
