import { C } from '../lib/theme';

export interface DayOption { key: string; label: string; }

/** Horizontal scrollable day chips — "All days" + one chip per match day. */
export function DayFilterBar({
  days, selectedKey, allDaysLabel, onSelect,
}: {
  days: DayOption[];
  selectedKey: string | null;
  allDaysLabel: string;
  onSelect: (key: string | null) => void;
}) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1" style={{ scrollbarWidth: 'none' }}>
      <Chip label={allDaysLabel} selected={selectedKey === null} onClick={() => onSelect(null)} />
      {days.map((d) => (
        <Chip
          key={d.key}
          label={d.label}
          selected={selectedKey === d.key}
          onClick={() => onSelect(d.key)}
        />
      ))}
    </div>
  );
}

function Chip({ label, selected, onClick }: { label: string; selected: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="whitespace-nowrap rounded-full px-3.5 py-1.5 text-[13px] font-bold transition"
      style={
        selected
          ? { background: C.pitchGreen, color: '#04130C', border: `1px solid ${C.pitchGreen}` }
          : { background: 'rgba(255,255,255,0.05)', color: 'rgba(255,255,255,0.85)', border: '1px solid rgba(255,255,255,0.15)' }
      }
    >
      {label}
    </button>
  );
}
