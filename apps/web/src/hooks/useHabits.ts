"use client";

import { useCallback, useEffect, useState } from "react";
import { createId, getTodayKey } from "@shared/pomodoro";
import { toggleHabitCompletion } from "@shared/habits";
import type { Habit } from "@shared/types";
import { loadHabits, saveHabits } from "@/lib/storage";

export function useHabits() {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHabits(loadHabits());
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    saveHabits(habits);
  }, [habits, hydrated]);

  const addHabit = useCallback(
    (title: string, emoji = "✅", targetPerWeek = 7) => {
      const trimmed = title.trim();
      if (!trimmed) return;
      const habit: Habit = {
        id: createId(),
        title: trimmed,
        emoji,
        completions: [],
        createdAt: new Date().toISOString(),
        targetPerWeek: Math.min(7, Math.max(1, targetPerWeek)),
      };
      setHabits((prev) => [habit, ...prev]);
    },
    [],
  );

  const updateHabit = useCallback(
    (
      id: string,
      patch: Partial<Pick<Habit, "title" | "emoji" | "targetPerWeek">>,
    ) => {
      setHabits((prev) =>
        prev.map((h) => (h.id === id ? { ...h, ...patch } : h)),
      );
    },
    [],
  );

  const deleteHabit = useCallback((id: string) => {
    setHabits((prev) => prev.filter((h) => h.id !== id));
  }, []);

  const toggleDate = useCallback((id: string, date = getTodayKey()) => {
    setHabits((prev) =>
      prev.map((h) => (h.id === id ? toggleHabitCompletion(h, date) : h)),
    );
  }, []);

  return { habits, addHabit, updateHabit, deleteHabit, toggleDate, hydrated };
}
