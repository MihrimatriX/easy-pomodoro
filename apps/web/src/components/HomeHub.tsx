"use client";

import { BarChart3, Shield, Target, Timer } from "lucide-react";
import { useEffect, useState } from "react";
import { getTodayHabitProgress } from "@shared/habits";
import type { Habit } from "@shared/types";
import type { TabId } from "@/components/nav-tabs";
import { greetingKey, type MessageKey } from "@shared/i18n/messages";
import { useT } from "@/context/LocaleContext";

type HomeHubProps = {
  sessionsToday: number;
  totalFocusMinutes: number;
  habits: Habit[];
  onNavigate: (tab: TabId) => void;
};

export function HomeHub({
  sessionsToday,
  totalFocusMinutes,
  habits,
  onNavigate,
}: HomeHubProps) {
  const t = useT();
  const [hello, setHello] = useState<MessageKey>("goodMorning");

  useEffect(() => {
    setHello(greetingKey());
  }, []);

  const { completed, total } = getTodayHabitProgress(habits);

  const habitPct = total > 0 ? Math.round((completed / total) * 100) : 0;

  const NAV_CARDS = [
    {
      tab: "pomodoro" as const,
      icon: Timer,
      title: t("startPomodoro"),
      statKey: "pomodoro" as const,
    },

    {
      tab: "habits" as const,
      icon: Target,
      title: t("navHabits"),
      statKey: "habits" as const,
    },

    {
      tab: "stats" as const,
      icon: BarChart3,
      title: t("weeklySummary"),
      statKey: "focus" as const,
    },
  ];

  const metaFor = (key: (typeof NAV_CARDS)[number]["statKey"]) => {
    if (key === "pomodoro") return t("pomodoroToday", { n: sessionsToday });

    if (key === "habits")
      return t("habitsToday", { done: completed, total, pct: habitPct });

    return t("focusTotal", { min: totalFocusMinutes });
  };

  return (
    <div className="home-hub flex w-full flex-1 flex-col">
      <header className="hero-block shrink-0 mobile-only">
        <div className="hero-orb" aria-hidden>
          ⏱
        </div>

        <div>
          <p className="page-title text-foreground">{t("appName")}</p>

          <p className="page-sub">{t("tagline")}</p>
        </div>
      </header>

      <div className="desktop-only">
        <h2 className="page-title text-foreground">{t(hello)}</h2>

        <p className="page-sub mb-6">{t("homeIntro")}</p>
      </div>

      <section className="card-grid card-grid-2 mb-6 shrink-0">
        <div className="neo-surface stat-card">
          <p className="section-label">{t("today")}</p>

          <p className="stat-value">{sessionsToday}</p>

          <p className="mt-1.5 text-sm font-medium text-muted">
            {t("completedPomodoros")}
          </p>
        </div>

        <div className="neo-surface stat-card">
          <p className="section-label">{t("focus")}</p>

          <p className="stat-value">
            {totalFocusMinutes}

            <span className="text-lg text-muted"> {t("minutesShort")}</span>
          </p>

          <p className="mt-1.5 text-sm font-medium text-muted">
            {t("totalTime")}
          </p>
        </div>

        <div className="neo-surface stat-card desktop-only">
          <p className="section-label">{t("habit")}</p>

          <p className="stat-value">
            {completed}

            <span className="text-lg text-muted">/{total}</span>
          </p>

          {total > 0 && (
            <div className="neo-progress-track mt-3 h-2.5">
              <div
                className="neo-progress-fill h-full"
                style={{ width: `${habitPct}%` }}
              />
            </div>
          )}
        </div>
      </section>

      <p className="section-label shrink-0">{t("quickNav")}</p>

      <section className="card-grid card-grid-3 mb-5 min-h-0 flex-1">
        {NAV_CARDS.map(({ tab, icon: Icon, title, statKey }) => (
          <button
            key={tab}
            type="button"
            onClick={() => onNavigate(tab)}
            className="quick-card neo-surface"
          >
            <span className="quick-icon text-accent">
              <Icon size={20} />
            </span>

            <div className="min-w-0 flex-1">
              <p className="label text-foreground">{title}</p>

              <p className="meta">{metaFor(statKey)}</p>

              {statKey === "habits" && total > 0 && (
                <div className="neo-progress-track mt-3 h-2.5 mobile-only">
                  <div
                    className="neo-progress-fill h-full"
                    style={{ width: `${habitPct}%` }}
                  />
                </div>
              )}
            </div>
          </button>
        ))}
      </section>

      <section className="neo-surface-sm privacy-chip mt-auto shrink-0">
        <Shield size={16} className="shrink-0 text-accent" />

        <p>{t("privacyNote")}</p>
      </section>
    </div>
  );
}
