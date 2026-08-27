"use client";

import { RotateCcw, SkipForward, Pause, Play } from "lucide-react";
import type { TimerStatus } from "@shared/types";
import { useT } from "@/context/LocaleContext";

type TimerControlsProps = {
  status: TimerStatus;
  onStart: () => void;
  onPause: () => void;
  onResume: () => void;
  onReset: () => void;
  onSkip: () => void;
};

export function TimerControls({
  status,
  onStart,
  onPause,
  onResume,
  onReset,
  onSkip,
}: TimerControlsProps) {
  const t = useT();

  return (
    <div className="flex flex-col items-center gap-4">
      {status === "idle" && (
        <button
          type="button"
          onClick={onStart}
          className="neo-btn-primary flex h-14 min-w-[160px] items-center justify-center gap-2.5 px-8 text-lg font-semibold"
        >
          <Play size={22} fill="currentColor" />
          {t("start")}
        </button>
      )}
      {status === "running" && (
        <button
          type="button"
          onClick={onPause}
          className="neo-btn flex h-14 min-w-[160px] items-center justify-center gap-2.5 px-8 text-lg font-semibold text-foreground"
        >
          <Pause size={22} />
          {t("pause")}
        </button>
      )}
      {status === "paused" && (
        <button
          type="button"
          onClick={onResume}
          className="neo-btn-primary flex h-14 min-w-[160px] items-center justify-center gap-2.5 px-8 text-lg font-semibold"
        >
          <Play size={22} fill="currentColor" />
          {t("resume")}
        </button>
      )}

      <div className="neo-control-group">
        <button
          type="button"
          onClick={onReset}
          className="neo-icon-btn text-muted"
          aria-label={t("reset")}
          title={t("reset")}
        >
          <RotateCcw size={18} strokeWidth={2.25} />
        </button>
        <button
          type="button"
          onClick={onSkip}
          className="neo-icon-btn text-muted"
          aria-label={t("skip")}
          title={t("skipTitle")}
        >
          <SkipForward size={18} strokeWidth={2.25} />
        </button>
      </div>
    </div>
  );
}
