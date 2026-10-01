"use client";

import { Check } from "lucide-react";
import { phaseLabel } from "@shared/i18n/messages";
import { formatTime } from "@shared/pomodoro";
import { NeoSelect } from "@/components/NeoSelect";
import type { Phase, Task } from "@shared/types";
import { useLocale, useT } from "@/context/LocaleContext";

type TimerDisplayProps = {
  phase: Phase;
  remainingSec: number;
  progress: number;
  pomodoroCount: number;
  longBreakInterval: number;
};

type ActiveTaskCardProps = {
  tasks: Task[];
  activeTaskId: string | null;
  onSelectActive: (id: string | null) => void;
  onToggleTask: (id: string) => void;
  completedPomodoros: number;
  className?: string;
};

const PHASE_CLASS: Record<Phase, string> = {
  focus: "phase-focus",
  shortBreak: "phase-short",
  longBreak: "phase-long",
};

export function TimerDisplay({
  phase,
  remainingSec,
  progress,
  pomodoroCount,
  longBreakInterval,
}: TimerDisplayProps) {
  const t = useT();
  const locale = useLocale();
  const radius = 118;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - progress);
  const sessionCurrent = pomodoroCount % longBreakInterval;

  return (
    <div className="timer-display-wrap">
      <div className={`timer-shell ${PHASE_CLASS[phase]}`}>
        <div className="neo-timer-outer neo-timer-lg">
          <svg viewBox="0 0 260 260" className="timer-ring" aria-hidden>
            <circle className="track" cx={130} cy={130} r={radius} />

            <circle
              className="progress"
              cx={130}
              cy={130}
              r={radius}
              strokeDasharray={circumference}
              strokeDashoffset={offset}
            />
          </svg>

          <div className="neo-timer-inner">
            <span className="timer-display">{formatTime(remainingSec)}</span>
          </div>
        </div>

        <p className="phase-label">{phaseLabel(locale, phase)}</p>
      </div>

      <p className="timer-session-meta">
        {t("sessionMeta", {
          current: sessionCurrent,
          total: longBreakInterval,
        })}
      </p>
    </div>
  );
}

/** Active task picker — rendered under the timer controls so the primary
 *  Start button stays above the fold on phones. */
export function ActiveTaskCard({
  tasks,
  activeTaskId,
  onSelectActive,
  onToggleTask,
  completedPomodoros,
  className = "",
}: ActiveTaskCardProps) {
  const t = useT();
  const activeTask = tasks.find((task) => task.id === activeTaskId) || null;
  const estimated = activeTask?.estimatedPomodoros ?? 0;

  return (
    <div className={`active-task-card neo-surface ${className}`}>
      <p className="section-label">{t("activeTask")}</p>

      {activeTask ? (
        <div className="flex flex-col gap-3">
          <div className="flex items-center gap-2.5">
            <button
              type="button"
              onClick={() => onToggleTask(activeTask.id)}
              className={`task-check-btn ${
                activeTask.completed
                  ? "task-check-btn-done neo-btn-primary"
                  : "neo-inset-sm"
              }`}
            >
              {activeTask.completed && (
                <Check size={12} className="stroke-[3px] text-white" />
              )}
            </button>

            <p
              className={`min-w-0 flex-1 truncate text-base font-semibold text-foreground ${
                activeTask.completed ? "task-title done" : ""
              }`}
            >
              {activeTask.title}
            </p>

            <NeoSelect
              value={activeTask.id}
              onChange={(v) => onSelectActive(v || null)}
              className="max-w-[100px] shrink-0"
              ariaLabel={t("changeTask")}
            >
              <option value={activeTask.id}>{t("changeTask")}</option>

              <option value="">{t("dropTask")}</option>

              {tasks

                .filter((task) => !task.completed && task.id !== activeTask.id)

                .map((task) => (
                  <option key={task.id} value={task.id}>
                    {task.title}
                  </option>
                ))}
            </NeoSelect>
          </div>

          {(completedPomodoros > 0 || estimated > 0) && (
            <div className="pomo-dots">
              {Array.from({
                length: Math.min(Math.max(completedPomodoros, estimated, 1), 8),
              }).map((_, i) => (
                <span
                  key={i}
                  className={`pomo-dot ${i < completedPomodoros ? "filled" : ""}`}
                />
              ))}
            </div>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          <p className="text-sm font-medium text-muted">{t("noActiveTask")}</p>

          <NeoSelect
            value=""
            onChange={(v) => onSelectActive(v || null)}
            className="w-full"
            ariaLabel={t("selectTask")}
          >
            <option value="">{t("selectTask")}</option>

            {tasks

              .filter((task) => !task.completed)

              .map((task) => (
                <option key={task.id} value={task.id}>
                  {task.title}
                </option>
              ))}
          </NeoSelect>
        </div>
      )}
    </div>
  );
}
