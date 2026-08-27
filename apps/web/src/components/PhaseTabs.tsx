"use client";

import { phaseLabel } from "@shared/i18n/messages";
import type { Phase } from "@shared/types";
import { useLocale } from "@/context/LocaleContext";

type PhaseTabsProps = {
  phase: Phase;
  onSelect: (phase: Phase) => void;
  disabled?: boolean;
};

const phases: Phase[] = ["focus", "shortBreak", "longBreak"];

export function PhaseTabs({ phase, onSelect, disabled }: PhaseTabsProps) {
  const locale = useLocale();

  return (
    <div className="phase-tabs">
      <div className="neo-pill-track flex w-full gap-1 p-1">
        {phases.map((p) => (
          <button
            key={p}
            type="button"
            disabled={disabled}
            onClick={() => onSelect(p)}
            className={`flex-1 cursor-pointer disabled:cursor-not-allowed disabled:opacity-40 ${
              phase === p ? "neo-pill-active" : "neo-pill-item"
            }`}
          >
            {phaseLabel(locale, p)}
          </button>
        ))}
      </div>
    </div>
  );
}
