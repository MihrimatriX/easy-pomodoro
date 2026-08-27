import { getHabitStreak } from "./habits";
import { getNextPhase, getTodayKey, sessionDayKey } from "./pomodoro";
import { DEFAULT_SETTINGS } from "./types";

/** ponytail: fails loud if phase math or local dates break. */
export function runSelfCheck(): void {
  const s = { ...DEFAULT_SETTINGS, longBreakInterval: 4 };

  const first = getNextPhase("focus", 0, s);
  if (first.phase !== "shortBreak" || first.pomodoroCount !== 1) {
    throw new Error("pomodoro: first focus should go to short break");
  }

  const fourth = getNextPhase("focus", 3, s);
  if (fourth.phase !== "longBreak" || fourth.pomodoroCount !== 4) {
    throw new Error("pomodoro: 4th focus should go to long break");
  }

  const skipped = getNextPhase("focus", 3, s, { countFocus: false });
  if (skipped.phase !== "shortBreak" || skipped.pomodoroCount !== 3) {
    throw new Error("pomodoro: skip must not count a tomato");
  }

  const afterBreak = getNextPhase("shortBreak", 2, s);
  if (afterBreak.phase !== "focus" || afterBreak.pomodoroCount !== 2) {
    throw new Error("pomodoro: break should return to focus");
  }

  const localMidnight = new Date(2026, 0, 2, 0, 30, 0);
  if (getTodayKey(localMidnight) !== "2026-01-02") {
    throw new Error("date: today key must be local, not UTC");
  }

  const iso = localMidnight.toISOString();
  if (sessionDayKey(iso) !== "2026-01-02") {
    throw new Error("date: session day must match local calendar");
  }

  const today = getTodayKey();
  const streak = getHabitStreak({
    id: "x",
    title: "t",
    emoji: "✅",
    completions: [today],
    createdAt: today,
  });
  if (streak !== 1) {
    throw new Error("habit: today completion should be a 1-day streak");
  }
}

runSelfCheck();
