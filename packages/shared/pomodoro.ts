import type { Phase, Settings } from "./types";
import { getThemePalette } from "./themes";

export function getPhaseDurationMs(phase: Phase, settings: Settings): number {
  const minutes =
    phase === "focus"
      ? settings.focusMin
      : phase === "shortBreak"
        ? settings.shortBreakMin
        : settings.longBreakMin;
  return minutes * 60 * 1000;
}

export function getPhaseDurationSec(phase: Phase, settings: Settings): number {
  return getPhaseDurationMs(phase, settings) / 1000;
}

export function formatTime(totalSeconds: number): string {
  const seconds = Math.max(0, Math.ceil(totalSeconds));
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

export function getNextPhase(
  current: Phase,
  pomodoroCount: number,
  settings: Settings,
  options?: { countFocus?: boolean },
): { phase: Phase; pomodoroCount: number } {
  if (current !== "focus") {
    return { phase: "focus", pomodoroCount };
  }
  const countFocus = options?.countFocus !== false;
  if (!countFocus) {
    return { phase: "shortBreak", pomodoroCount };
  }
  const newCount = pomodoroCount + 1;
  const interval = Math.max(1, settings.longBreakInterval);
  if (newCount % interval === 0) {
    return { phase: "longBreak", pomodoroCount: newCount };
  }
  return { phase: "shortBreak", pomodoroCount: newCount };
}

export function getPhaseColor(phase: Phase, settings?: Settings): string {
  if (settings) {
    const palette = getThemePalette(settings);
    switch (phase) {
      case "focus":
        return palette.focus;
      case "shortBreak":
        return palette.shortBreak;
      case "longBreak":
        return palette.longBreak;
    }
  }
  switch (phase) {
    case "focus":
      return "#ef4444";
    case "shortBreak":
      return "#22c55e";
    case "longBreak":
      return "#3b82f6";
  }
}

/** Yerel takvim günü — UTC `toISOString` gece yarısı kaydırır. */
export function getTodayKey(date = new Date()): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function sessionDayKey(iso: string): string {
  const parsed = new Date(iso);
  if (Number.isNaN(parsed.getTime())) return iso.slice(0, 10);
  return getTodayKey(parsed);
}

export function getLast7Days(): string[] {
  const days: string[] = [];
  for (let i = 6; i >= 0; i -= 1) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push(getTodayKey(d));
  }
  return days;
}

export function getLast28Days(): string[] {
  const days: string[] = [];
  for (let i = 27; i >= 0; i -= 1) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push(getTodayKey(d));
  }
  return days;
}

export function createId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}
