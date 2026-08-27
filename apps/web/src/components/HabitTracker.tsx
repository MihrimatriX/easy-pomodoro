"use client";

import { Plus } from "lucide-react";
import { useState } from "react";
import { getLast7Days } from "@shared/pomodoro";
import {
  getTodayHabitProgress,
  HABIT_EMOJIS,
  sortHabitsForToday,
} from "@shared/habits";
import type { Habit } from "@shared/types";
import { useT } from "@/context/LocaleContext";
import { HabitCard } from "@/components/HabitCard";
import { NeoSelect } from "@/components/NeoSelect";

type HabitTrackerProps = {
  habits: Habit[];
  onAdd: (title: string, emoji: string, targetPerWeek: number) => void;
  onToggleDate: (id: string, date: string) => void;
  onUpdate: (id: string, patch: Partial<Pick<Habit, "targetPerWeek">>) => void;
  onDelete: (id: string) => void;
};

export function HabitTracker({
  habits,
  onAdd,
  onToggleDate,
  onUpdate,
  onDelete,
}: HabitTrackerProps) {
  const t = useT();
  const [title, setTitle] = useState("");
  const [emoji, setEmoji] = useState("✅");
  const [targetPerWeek, setTargetPerWeek] = useState(7);
  const [showForm, setShowForm] = useState(false);
  const weekDays = getLast7Days();
  const progress = getTodayHabitProgress(habits);
  const sorted = sortHabitsForToday(habits);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onAdd(title, emoji, targetPerWeek);
    setTitle("");
    setShowForm(false);
  };

  return (
    <section className="flex w-full max-w-lg flex-col gap-5 content-panel">
      <article className="neo-surface p-5">
        <div className="flex items-center justify-between">
          <header>
            <p className="text-base font-medium text-muted">
              {t("habitProgress")}
            </p>
            <p className="text-3xl font-bold text-foreground">
              {progress.completed}
              <span className="text-lg font-normal text-muted">
                /{progress.total}
              </span>
            </p>
          </header>
          <div
            aria-hidden
            className="neo-inset relative flex h-16 w-16 items-center justify-center rounded-full"
            style={{
              background: `conic-gradient(var(--accent) ${progress.percent * 3.6}deg, var(--border) 0)`,
            }}
          >
            <span className="flex h-12 w-12 items-center justify-center rounded-full bg-[var(--card)] text-base font-bold text-accent">
              {progress.percent}%
            </span>
          </div>
        </div>
        <div className="neo-progress-track mt-3 h-2 overflow-hidden">
          <div
            className="neo-progress-fill h-full transition-all duration-500"
            style={{ width: `${progress.percent}%` }}
          />
        </div>
      </article>

      {!showForm ? (
        <button
          type="button"
          onClick={() => setShowForm(true)}
          className="neo-inset flex items-center justify-center gap-2 py-4 text-base font-medium text-muted transition cursor-pointer hover:text-accent"
        >
          <Plus size={18} />
          {t("addHabit")}
        </button>
      ) : (
        <form onSubmit={handleSubmit} className="neo-surface p-4">
          <p className="mb-3 text-base font-semibold text-foreground">
            {t("newHabit")}
          </p>
          <div className="mb-3 flex flex-wrap gap-1.5">
            {HABIT_EMOJIS.map((e) => (
              <button
                key={e}
                type="button"
                onClick={() => setEmoji(e)}
                className={`flex h-9 w-9 items-center justify-center rounded-xl text-base transition cursor-pointer ${
                  emoji === e ? "neo-pill-active !p-0" : "neo-inset-sm"
                }`}
              >
                {e}
              </button>
            ))}
          </div>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={t("habitPlaceholder")}
            autoFocus
            className="neo-input mb-3 w-full px-4 py-3 text-foreground"
          />
          <label className="mb-3 flex flex-col gap-2 text-base text-muted sm:flex-row sm:items-center sm:justify-between">
            <span className="font-medium">{t("weeklyTarget")}</span>
            <NeoSelect
              value={String(targetPerWeek)}
              onChange={(v) => setTargetPerWeek(Number(v))}
              className="w-full sm:w-auto sm:min-w-[10rem]"
              ariaLabel={t("weeklyTarget")}
            >
              {[1, 2, 3, 4, 5, 6, 7].map((n) => (
                <option key={n} value={n}>
                  {t("daysPerWeek", { n })}
                </option>
              ))}
            </NeoSelect>
          </label>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setShowForm(false)}
              className="neo-btn flex-1 py-2.5 text-base font-medium text-muted"
            >
              {t("cancel")}
            </button>
            <button
              type="submit"
              disabled={!title.trim()}
              className="neo-btn-primary flex-1 py-2.5 text-base font-semibold disabled:opacity-40"
            >
              {t("add")}
            </button>
          </div>
        </form>
      )}

      {habits.length === 0 ? (
        <article className="neo-surface px-6 py-12 text-center">
          <p className="text-4xl">🎯</p>
          <p className="mt-3 text-lg font-semibold text-foreground">
            {t("noHabits")}
          </p>
          <p className="mt-1 text-base text-muted">{t("noHabitsHint")}</p>
        </article>
      ) : (
        <ul className="flex flex-col gap-4">
          {sorted.map((habit) => (
            <HabitCard
              key={habit.id}
              habit={habit}
              weekDays={weekDays}
              onToggleDate={onToggleDate}
              onUpdate={onUpdate}
              onDelete={onDelete}
            />
          ))}
        </ul>
      )}
    </section>
  );
}
