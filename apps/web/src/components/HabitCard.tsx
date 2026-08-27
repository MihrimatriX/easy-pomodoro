"use client";

import { ChevronDown, Flame, Trophy, Trash2 } from "lucide-react";
import { NeoSelect } from "@/components/NeoSelect";
import { getLast28Days, getTodayKey } from "@shared/pomodoro";
import {
  getDayLabel,
  getHabitStats,
  getHabitTargetPerWeek,
  isHabitDoneOnDate,
} from "@shared/habits";
import type { Habit } from "@shared/types";
import { useLocale, useT } from "@/context/LocaleContext";

type HabitCardProps = {
  habit: Habit;
  weekDays: string[];
  onToggleDate: (id: string, date: string) => void;
  onUpdate: (id: string, patch: Partial<Pick<Habit, "targetPerWeek">>) => void;
  onDelete: (id: string) => void;
};

export function HabitCard({
  habit,
  weekDays,
  onToggleDate,
  onUpdate,
  onDelete,
}: HabitCardProps) {
  const stats = getHabitStats(habit, weekDays);
  const monthDays = getLast28Days();
  const today = getTodayKey();
  const t = useT();
  const locale = useLocale();

  const handleDelete = () => {
    if (window.confirm(t("confirmDeleteHabit", { title: habit.title }))) {
      onDelete(habit.id);
    }
  };

  return (
    <li
      className={`neo-surface p-4 transition ${
        stats.doneToday ? "ring-1 ring-accent/30" : ""
      }`}
    >
      <div className="flex items-start gap-3">
        <button
          type="button"
          onClick={() => onToggleDate(habit.id, today)}
          className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl text-xl transition cursor-pointer active:scale-95 ${
            stats.doneToday
              ? "neo-btn-primary !rounded-2xl !p-0"
              : "neo-inset-sm"
          }`}
        >
          {stats.doneToday ? "✓" : habit.emoji}
        </button>

        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <div>
              <p
                className={`text-base font-semibold text-foreground ${stats.doneToday ? "line-through opacity-70" : ""}`}
              >
                {habit.title}
              </p>
              <div className="mt-2 flex flex-wrap gap-2">
                <span className="neo-badge neo-badge-accent">
                  <Flame size={12} />
                  {t("streakDays", { n: stats.streak })}
                </span>
                <span className="neo-badge">
                  <Trophy size={12} />
                  {t("bestStreakLabel", { n: stats.bestStreak })}
                </span>
                <span className="neo-badge">
                  {t("totalCompletionsLabel", { n: stats.totalCompletions })}
                </span>
              </div>
            </div>
            <button
              type="button"
              onClick={handleDelete}
              className="neo-icon-btn shrink-0 p-1.5 text-muted hover:!text-accent"
              aria-label={t("delete")}
            >
              <Trash2 size={16} />
            </button>
          </div>

          <div className="mt-3">
            <div className="mb-1 flex items-center justify-between text-sm text-muted">
              <span>{t("thisWeek")}</span>
              <span className="font-medium text-foreground">
                {t("weekProgress", {
                  done: stats.weekDone,
                  target: stats.weekTarget,
                })}
              </span>
            </div>
            <div className="neo-progress-track h-1.5 overflow-hidden">
              <div
                className="neo-progress-fill h-full transition-all"
                style={{ width: `${stats.weekPercent}%` }}
              />
            </div>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <label
                htmlFor={`target-${habit.id}`}
                className="text-sm font-medium text-muted"
              >
                {t("weeklyTarget")}
              </label>
              <NeoSelect
                value={String(getHabitTargetPerWeek(habit))}
                onChange={(v) =>
                  onUpdate(habit.id, { targetPerWeek: Number(v) })
                }
                className="min-w-[9.5rem]"
                ariaLabel={t("weeklyTarget")}
              >
                {[1, 2, 3, 4, 5, 6, 7].map((n) => (
                  <option key={n} value={n}>
                    {t("daysPerWeek", { n })}
                  </option>
                ))}
              </NeoSelect>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-4">
        <p className="mb-2 text-sm font-medium text-muted">
          {t("last7Days")}
        </p>
        <div className="flex justify-between gap-1">
          {weekDays.map((day) => {
            const done = isHabitDoneOnDate(habit, day);
            const isToday = day === today;
            return (
              <button
                key={day}
                type="button"
                onClick={() => onToggleDate(habit.id, day)}
                className="group flex flex-1 cursor-pointer flex-col items-center gap-1.5"
              >
                <span className="text-xs font-medium text-muted">
                  {getDayLabel(day, locale)}
                </span>
                <span
                  className={`flex h-9 w-full max-w-[36px] items-center justify-center rounded-xl text-sm font-bold transition active:scale-90 ${
                    done
                      ? "neo-btn-primary !rounded-xl !p-0 text-white"
                      : "neo-inset-sm text-muted group-hover:text-foreground"
                  } ${isToday ? "ring-2 ring-accent/40 ring-offset-2 ring-offset-[var(--background)]" : ""}`}
                >
                  {done ? "✓" : day.slice(8)}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      <details className="group mt-4">
        <summary className="neo-details-trigger">
          <ChevronDown
            size={14}
            className="transition duration-200 group-open:rotate-180"
          />
          {t("last4Weeks")}
        </summary>
        <div className="mt-2 grid grid-cols-7 gap-1">
          {monthDays.map((day) => (
            <div
              key={day}
              title={day}
              className={`aspect-square rounded-sm ${
                isHabitDoneOnDate(habit, day)
                  ? "bg-accent shadow-[0_0_6px_var(--neo-accent-glow)]"
                  : "neo-inset-sm !rounded-sm"
              } ${day === today ? "ring-1 ring-accent/60" : ""}`}
            />
          ))}
        </div>
      </details>
    </li>
  );
}
