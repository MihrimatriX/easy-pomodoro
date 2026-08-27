import { getTodayKey } from "./pomodoro";
import type { Habit, LocaleId } from "./types";

export const HABIT_EMOJIS = [
  "✅",
  "💧",
  "📚",
  "🏃",
  "🧘",
  "💤",
  "🥗",
  "✍️",
  "🎯",
  "💪",
  "🚶",
  "🧠",
  "📵",
  "🎸",
  "🧹",
  "💊",
] as const;

export function getDayLabel(dateKey: string, locale: LocaleId = "tr"): string {
  const d = new Date(`${dateKey}T12:00:00`);
  return new Intl.DateTimeFormat(locale === "en" ? "en-US" : "tr-TR", {
    weekday: "short",
  }).format(d);
}

export function isHabitDoneOnDate(habit: Habit, date: string): boolean {
  return habit.completions.includes(date);
}

export function isHabitDoneToday(habit: Habit): boolean {
  return isHabitDoneOnDate(habit, getTodayKey());
}

export function getHabitTargetPerWeek(habit: Habit): number {
  return habit.targetPerWeek ?? 7;
}

export function toggleHabitCompletion(habit: Habit, date: string): Habit {
  const has = habit.completions.includes(date);
  return {
    ...habit,
    completions: has
      ? habit.completions.filter((d) => d !== date)
      : [...habit.completions, date].sort(),
  };
}

/** Aktif seri: bugün yapılmadıysa dünden sayar */
export function getHabitStreak(habit: Habit, today = getTodayKey()): number {
  const set = new Set(habit.completions);
  const cursor = new Date(`${today}T12:00:00`);

  if (!set.has(today)) {
    cursor.setDate(cursor.getDate() - 1);
  }

  let streak = 0;
  while (true) {
    const key = getTodayKey(cursor);
    if (!set.has(key)) break;
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

export function getBestStreak(habit: Habit): number {
  if (habit.completions.length === 0) return 0;

  const sorted = [...habit.completions].sort();
  let best = 1;
  let current = 1;

  for (let i = 1; i < sorted.length; i += 1) {
    const prev = new Date(`${sorted[i - 1]}T12:00:00`);
    const curr = new Date(`${sorted[i]}T12:00:00`);
    const diffDays = Math.round((curr.getTime() - prev.getTime()) / 86400000);
    if (diffDays === 1) {
      current += 1;
      best = Math.max(best, current);
    } else if (diffDays > 1) {
      current = 1;
    }
  }

  return best;
}

export function getWeeklyCompletionCount(habit: Habit, days: string[]): number {
  return days.filter((d) => habit.completions.includes(d)).length;
}

export function isWeeklyTargetMet(habit: Habit, days: string[]): boolean {
  return getWeeklyCompletionCount(habit, days) >= getHabitTargetPerWeek(habit);
}

export function getTodayHabitProgress(habits: Habit[]): {
  completed: number;
  total: number;
  percent: number;
} {
  const total = habits.length;
  const completed = habits.filter(isHabitDoneToday).length;
  return {
    completed,
    total,
    percent: total === 0 ? 0 : Math.round((completed / total) * 100),
  };
}

export function sortHabitsForToday(habits: Habit[]): Habit[] {
  return [...habits].sort((a, b) => {
    const aDone = isHabitDoneToday(a);
    const bDone = isHabitDoneToday(b);
    if (aDone !== bDone) return aDone ? 1 : -1;
    return getHabitStreak(b) - getHabitStreak(a);
  });
}

export type HabitStats = {
  streak: number;
  bestStreak: number;
  doneToday: boolean;
  weekDone: number;
  weekTarget: number;
  weekPercent: number;
  totalCompletions: number;
};

export function getHabitStats(habit: Habit, weekDays: string[]): HabitStats {
  const weekTarget = getHabitTargetPerWeek(habit);
  const weekDone = getWeeklyCompletionCount(habit, weekDays);
  return {
    streak: getHabitStreak(habit),
    bestStreak: getBestStreak(habit),
    doneToday: isHabitDoneToday(habit),
    weekDone,
    weekTarget,
    weekPercent: Math.min(100, Math.round((weekDone / weekTarget) * 100)),
    totalCompletions: habit.completions.length,
  };
}

export function getWeekCompletionRate(habit: Habit, days: string[]): number {
  if (days.length === 0) return 0;
  const done = days.filter((d) => habit.completions.includes(d)).length;
  return Math.round((done / days.length) * 100);
}
