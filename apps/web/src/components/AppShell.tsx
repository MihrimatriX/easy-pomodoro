"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  showPhaseNotification,
  requestNotificationPermission,
} from "@/lib/notifications";
import { playCompletionSound } from "@/lib/sounds";
import { usePomodoro } from "@/hooks/usePomodoro";
import { useSettings } from "@/hooks/useSettings";
import { useTasks } from "@/hooks/useTasks";
import { useStats } from "@/hooks/useStats";
import { useHabits } from "@/hooks/useHabits";
import { BottomNav, type TabId } from "@/components/BottomNav";
import { SidebarNav } from "@/components/SidebarNav";
import { ThemeApplier } from "@/components/ThemeApplier";
import { HomeHub } from "@/components/HomeHub";
import { HabitTracker } from "@/components/HabitTracker";
import { TimerDisplay } from "@/components/TimerDisplay";
import { TimerControls } from "@/components/TimerControls";
import { PhaseTabs } from "@/components/PhaseTabs";
import { TaskList } from "@/components/TaskList";
import { StatsView } from "@/components/StatsView";
import { SettingsPanel } from "@/components/SettingsPanel";
import { Confetti } from "@/components/Confetti";
import { getTodayHabitProgress } from "@shared/habits";
import { formatTime } from "@shared/pomodoro";
import { phaseLabel } from "@shared/i18n/messages";
import { LocaleProvider, useLocale, useT } from "@/context/LocaleContext";
import { useWakeLock } from "@/hooks/useWakeLock";
import type { Phase, Settings } from "@shared/types";

type PomodoroView = "timer" | "tasks";

function AppShellInner({
  settings,
  setSettings,
}: {
  settings: Settings;
  setSettings: (patch: Partial<Settings>) => void;
}) {
  const t = useT();
  const locale = useLocale();
  const [tab, setTab] = useState<TabId>("home");
  const [pomodoroView, setPomodoroView] = useState<PomodoroView>("timer");
  const {
    tasks,
    activeTaskId,
    setActiveTaskId,
    addTask,
    toggleTask,
    updateTask,
    deleteTask,
  } = useTasks();
  const { habits, addHabit, updateHabit, deleteHabit, toggleDate } =
    useHabits();
  const { stats, logSession, deleteSession } = useStats();

  const handlePhaseComplete = useCallback(
    (completedPhase: Phase, durationSec: number) => {
      logSession(completedPhase, durationSec, activeTaskId ?? undefined);
    },
    [logSession, activeTaskId],
  );

  const pomodoro = usePomodoro(settings, {
    onPhaseComplete: handlePhaseComplete,
    onNotify: (completedPhase) =>
      showPhaseNotification(completedPhase, settings.locale),
    onSound: playCompletionSound,
  });

  useWakeLock(pomodoro.status === "running");

  useEffect(() => {
    const name = t("appName");
    if (pomodoro.status === "idle") {
      document.title = `${name} — ${t("tagline")}`;
      return;
    }
    const prefix = pomodoro.status === "paused" ? "⏸ " : "";
    document.title = `${prefix}${formatTime(pomodoro.remainingSec)} · ${phaseLabel(locale, pomodoro.phase)}`;
  }, [locale, pomodoro.phase, pomodoro.remainingSec, pomodoro.status, t]);

  const handleStart = async () => {
    if (settings.notifications) {
      await requestNotificationPermission();
    }
    pomodoro.start();
  };

  const habitProgress = getTodayHabitProgress(habits);

  const [confettiTrigger, setConfettiTrigger] = useState(0);
  const prevCompletedRef = useRef(-1);

  useEffect(() => {
    if (
      prevCompletedRef.current !== -1 &&
      habitProgress.completed > prevCompletedRef.current
    ) {
      setConfettiTrigger((prev) => prev + 1);
    }
    prevCompletedRef.current = habitProgress.completed;
  }, [habitProgress.completed]);

  const completedPomodoros = activeTaskId
    ? stats.allSessions.filter(
        (s) => s.phase === "focus" && s.taskId === activeTaskId,
      ).length
    : 0;

  const taskListProps = {
    tasks,
    activeTaskId,
    onAdd: addTask,
    onToggle: toggleTask,
    onUpdate: updateTask,
    onDelete: deleteTask,
    onSelectActive: setActiveTaskId,
    sessions: stats.allSessions,
  };

  return (
    <div className="app-shell">
      <div className="glow-aura" />
      <div className="ambient-orb ambient-orb-a" aria-hidden />
      <div className="ambient-orb ambient-orb-b" aria-hidden />
      <Confetti trigger={confettiTrigger} />
      <ThemeApplier settings={settings} />

      <div className="desktop-layout">
        <SidebarNav active={tab} onChange={setTab} />

        <div className="app-frame">
          <header className="mobile-header shrink-0 px-4 pb-2 pt-[max(0.75rem,env(safe-area-inset-top))] text-center">
            {tab !== "home" && (
              <>
                  <p className="page-title text-foreground">
                    {t("appName")}
                  </p>
                <p className="mx-auto mt-1 max-w-sm text-base leading-snug text-muted">
                  {t("tagline")}
                </p>
              </>
            )}
          </header>

          <main className={`app-main ${tab === "home" ? "app-main-home" : ""}`}>
            {tab === "home" && (
              <HomeHub
                sessionsToday={stats.sessionsToday}
                totalFocusMinutes={stats.totalFocusMinutes}
                habits={habits}
                onNavigate={setTab}
              />
            )}

            {tab === "pomodoro" && (
              <div className="pomodoro-page">
                <div className="pomodoro-view-tabs mobile-only">
                  {(
                    [
                      { id: "timer", label: t("timer") },
                      { id: "tasks", label: t("tasks") },
                    ] as const
                  ).map(({ id, label }) => (
                    <button
                      key={id}
                      type="button"
                      onClick={() => setPomodoroView(id)}
                      className={`flex-1 cursor-pointer ${
                        pomodoroView === id
                          ? "neo-pill-active"
                          : "neo-pill-item"
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>

                <div
                  className={`pomodoro-layout ${
                    pomodoroView === "tasks" ? "pomodoro-layout-tasks-only" : ""
                  }`}
                >
                  <div
                    className={`pomodoro-timer-col ${
                      pomodoroView === "tasks" ? "hide-on-mobile" : ""
                    }`}
                  >
                    <PhaseTabs
                      phase={pomodoro.phase}
                      onSelect={pomodoro.selectPhase}
                      disabled={pomodoro.status === "running"}
                    />
                    <TimerDisplay
                      phase={pomodoro.phase}
                      remainingSec={pomodoro.remainingSec}
                      progress={pomodoro.progress}
                      pomodoroCount={pomodoro.pomodoroCount}
                      longBreakInterval={settings.longBreakInterval}
                      tasks={tasks}
                      activeTaskId={activeTaskId}
                      onSelectActive={setActiveTaskId}
                      onToggleTask={toggleTask}
                      completedPomodoros={completedPomodoros}
                      hideActiveTaskOnDesktop
                    />
                    <TimerControls
                      status={pomodoro.status}
                      onStart={handleStart}
                      onPause={pomodoro.pause}
                      onResume={pomodoro.resume}
                      onReset={pomodoro.reset}
                      onSkip={pomodoro.skip}
                    />
                  </div>

                  <aside
                    className={`pomodoro-tasks-col neo-surface ${
                      pomodoroView === "timer"
                        ? "hide-on-mobile show-from-tablet"
                        : ""
                    }`}
                  >
                    <TaskList {...taskListProps} showTitle compact />
                  </aside>
                </div>
              </div>
            )}

            {tab === "habits" && (
              <HabitTracker
                habits={habits}
                onAdd={addHabit}
                onToggleDate={toggleDate}
                onUpdate={updateHabit}
                onDelete={deleteHabit}
              />
            )}

            {tab === "stats" && (
              <StatsView
                sessionsToday={stats.sessionsToday}
                totalFocusMinutes={stats.totalFocusMinutes}
                last7Days={stats.last7Days}
                allSessions={stats.allSessions}
                tasks={tasks}
                onDeleteSession={deleteSession}
                habitsCompletedToday={habitProgress.completed}
                habitsTotal={habitProgress.total}
              />
            )}

            {tab === "settings" && (
              <SettingsPanel settings={settings} onChange={setSettings} />
            )}
          </main>

          <BottomNav active={tab} onChange={setTab} />
        </div>
      </div>
    </div>
  );
}

export function AppShell() {
  const { settings, setSettings } = useSettings();
  return (
    <LocaleProvider locale={settings.locale}>
      <AppShellInner settings={settings} setSettings={setSettings} />
    </LocaleProvider>
  );
}
