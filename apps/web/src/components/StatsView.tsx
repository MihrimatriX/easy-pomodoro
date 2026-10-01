"use client";

import { Trash2, Calendar, List, PieChart, Info } from "lucide-react";
import { getLast28Days, getTodayKey, sessionDayKey } from "@shared/pomodoro";
import { useLocale, useT } from "@/context/LocaleContext";
import type { SessionLog, Task } from "@shared/types";

type StatsViewProps = {
  sessionsToday: number;
  totalFocusMinutes: number;
  last7Days: { day: string; count: number }[];
  allSessions: SessionLog[];
  tasks: Task[];
  onDeleteSession: (id: string) => void;
  habitsCompletedToday: number;
  habitsTotal: number;
};

export function StatsView({
  sessionsToday,
  totalFocusMinutes,
  last7Days,
  allSessions,
  tasks,
  onDeleteSession,
  habitsCompletedToday,
  habitsTotal,
}: StatsViewProps) {
  const tr = useT();
  const locale = useLocale();
  const maxCount = Math.max(1, ...last7Days.map((d) => d.count));
  const monthDays = getLast28Days();
  const today = getTodayKey();

  // Son 28 günün günlük odaklanma sayıları
  const focusSessions = allSessions.filter((s) => s.phase === "focus");

  const getDayCount = (dayKey: string) => {
    return focusSessions.filter((s) => sessionDayKey(s.completedAt) === dayKey)
      .length;
  };

  const getHeatmapClass = (count: number) => {
    if (count === 0) return "neo-inset-sm !rounded-md text-muted";
    if (count === 1) return "bg-accent/25 text-accent";
    if (count === 2) return "bg-accent/50 text-white";
    if (count === 3) return "bg-accent/75 text-white";
    return "bg-accent text-white shadow-[0_0_8px_var(--neo-accent-glow)]";
  };

  // Görev bazlı odak süreleri
  const taskBreakdown = tasks
    .map((task) => {
      const taskSessions = focusSessions.filter((s) => s.taskId === task.id);
      const minutes = Math.round(
        taskSessions.reduce((sum, s) => sum + s.durationSec, 0) / 60,
      );
      return {
        id: task.id,
        title: task.title,
        minutes,
        count: taskSessions.length,
        completed: task.completed,
      };
    })
    .filter((t) => t.count > 0)
    .sort((a, b) => b.minutes - a.minutes);

  // Görevle eşleşmeyen oturumlar (Genel Odaklanma)
  const generalSessions = focusSessions.filter((s) => !s.taskId);
  const generalMinutes = Math.round(
    generalSessions.reduce((sum, s) => sum + s.durationSec, 0) / 60,
  );

  // Son 10 odaklanma seansı listesi
  const recentSessions = [...focusSessions]
    .sort(
      (a, b) =>
        new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime(),
    )
    .slice(0, 10);

  const formatSessionTime = (isoString: string) => {
    const d = new Date(isoString);
    if (Number.isNaN(d.getTime())) return tr("unknownDate");
    return new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "tr-TR", {
      day: "2-digit",
      month: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    }).format(d);
  };

  const getTaskTitle = (taskId?: string) => {
    if (!taskId) return tr("generalFocus");
    const found = tasks.find((t) => t.id === taskId);
    return found ? found.title : tr("deletedTask");
  };

  const handleDeleteLog = (id: string, timeStr: string) => {
    if (window.confirm(tr("confirmDeleteSession", { time: timeStr }))) {
      onDeleteSession(id);
    }
  };

  return (
    <div className="flex w-full max-w-lg flex-col gap-6 pb-6 content-panel">
      {/* Bugün Özeti */}
      <h2 className="section-label flex items-center gap-1.5 pl-1">
        <Info size={16} /> {tr("statsToday")}
      </h2>
      <div className="grid grid-cols-2 gap-4">
        <div className="neo-surface p-5 transition">
          <p className="text-sm font-medium text-muted">
            {tr("statsCompleted")}
          </p>
          <p className="mt-1 text-3xl font-extrabold leading-none text-accent">
            {sessionsToday}
          </p>
          <p className="mt-1.5 text-sm font-semibold text-muted">
            {tr("statsSessions")}
          </p>
        </div>
        <div className="neo-surface p-5 transition">
          <p className="text-sm font-medium text-muted">
            {tr("statsTotalTime")}
          </p>
          <p className="mt-1 text-3xl font-extrabold text-accent leading-none">
            {totalFocusMinutes}
          </p>
          <p className="text-sm font-semibold text-muted mt-1.5">
            {tr("statsFocusMinutes")}
          </p>
        </div>
      </div>

      <div className="neo-surface p-5 transition">
        <p className="text-sm font-semibold text-muted">
          {tr("statsHabitsToday")}
        </p>
        <div className="mt-1 flex items-baseline gap-2">
          <span className="text-3xl font-extrabold text-accent">
            {habitsCompletedToday}
          </span>
          <span className="font-medium text-muted">
            / {habitsTotal} {tr("habitsDoneOf")}
          </span>
        </div>
        <div className="neo-progress-track mt-3.5 h-2 overflow-hidden">
          <div
            className="neo-progress-fill h-full transition-all duration-500"
            style={{
              width: `${habitsTotal > 0 ? (habitsCompletedToday / habitsTotal) * 100 : 0}%`,
            }}
          />
        </div>
      </div>

      {/* 7 Günlük Çubuk Grafik */}
      <div className="neo-surface p-5 transition">
        <p className="mb-4 flex items-center gap-1.5 text-sm font-semibold text-muted">
          <Calendar size={14} /> {tr("statsWeekChart")}
        </p>
        <div className="flex h-[132px] items-stretch justify-between gap-2.5 pt-2">
          {last7Days.map(({ day, count }) => (
            <div
              key={day}
              className="flex min-w-0 flex-1 flex-col items-center gap-1.5"
            >
              {/* flex-1 gives the bar a definite height to be a % of. */}
              <div className="flex w-full flex-1 flex-col items-center justify-end gap-1">
                {count > 0 && (
                  <span className="text-[0.6875rem] font-bold leading-none text-accent">
                    {count}
                  </span>
                )}
                <div
                  className="stats-bar w-full rounded-t-md"
                  style={{
                    // 82%: leaves headroom for the count label above the bar.
                    height: `${(count / maxCount) * 82}%`,
                    minHeight: count > 0 ? 8 : 3,
                    opacity: count > 0 ? 1 : 0.35,
                  }}
                  title={tr("sessionsCount", { n: count })}
                />
              </div>
              <span className="text-xs font-bold text-muted/80">
                {day.slice(8)}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* 28 Günlük Katvim Heatmap */}
      <div className="neo-surface p-5 transition">
        <p className="mb-3 flex items-center gap-1.5 text-sm font-semibold text-muted">
          <Calendar size={14} /> {tr("statsHeatmap")}
        </p>
        <div className="grid grid-cols-7 gap-1.5 max-w-[280px] mx-auto">
          {monthDays.map((day) => {
            const count = getDayCount(day);
            const isToday = day === today;
            return (
              <div
                key={day}
                title={`${day}: ${tr("sessionsCount", { n: count })}`}
                className={`aspect-square rounded-md flex items-center justify-center text-xs font-mono font-bold transition duration-300 ${getHeatmapClass(
                  count,
                )} ${
                  isToday
                    ? "ring-2 ring-accent/60 ring-offset-2 ring-offset-[var(--background)]"
                    : ""
                }`}
              >
                {day.slice(8)}
              </div>
            );
          })}
        </div>
        <div className="mt-3.5 flex justify-end items-center gap-1.5 text-xs font-semibold text-muted">
          <span>{tr("heatmapLow")}</span>
          <div className="neo-inset-sm !h-2 !w-2 !rounded-sm" />
          <div className="h-2 w-2 rounded-sm bg-accent/25" />
          <div className="h-2 w-2 rounded-sm bg-accent/50" />
          <div className="h-2 w-2 rounded-sm bg-accent/75" />
          <div className="h-2 w-2 rounded-sm bg-accent shadow-[0_0_4px_var(--neo-accent-glow)]" />
          <span>{tr("heatmapHigh")}</span>
        </div>
      </div>

      {/* Görev Dağılımı */}
      {(taskBreakdown.length > 0 || generalMinutes > 0) && (
        <div className="neo-surface p-5 transition">
          <p className="mb-4 flex items-center gap-1.5 text-sm font-semibold text-muted">
            <PieChart size={14} /> {tr("statsByTask")}
          </p>
          <div className="flex flex-col gap-3">
            {taskBreakdown.map((item) => (
              <div key={item.id} className="flex flex-col gap-1">
                <div className="flex items-center justify-between text-sm font-semibold">
                  <span className="truncate text-foreground max-w-[70%]">
                    {item.title}{" "}
                    {item.completed && (
                      <span className="ml-1 rounded-full bg-accent/10 px-1.5 py-0.5 text-xs text-accent">
                        {tr("done")}
                      </span>
                    )}
                  </span>
                  <span className="text-muted font-mono">
                    {item.minutes} {tr("minutesShort")}
                  </span>
                </div>
                <div className="neo-progress-track h-1.5 w-full overflow-hidden">
                  <div
                    className="neo-progress-fill h-full"
                    style={{
                      width: `${(item.minutes / totalFocusMinutes) * 100}%`,
                    }}
                  />
                </div>
              </div>
            ))}
            {generalMinutes > 0 && (
              <div className="flex flex-col gap-1">
                <div className="flex items-center justify-between text-sm font-semibold">
                  <span className="text-foreground">{tr("generalFocus")}</span>
                  <span className="text-muted font-mono">
                    {generalMinutes} {tr("minutesShort")}
                  </span>
                </div>
                <div className="neo-progress-track h-1.5 w-full overflow-hidden">
                  <div
                    className="neo-progress-fill h-full opacity-60"
                    style={{
                      width: `${(generalMinutes / totalFocusMinutes) * 100}%`,
                    }}
                  />
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Seans Geçmişi */}
      <div className="neo-surface p-5 transition">
        <p className="mb-4 flex items-center gap-1.5 text-sm font-semibold text-muted">
          <List size={14} /> {tr("statsRecent")}
        </p>
        {recentSessions.length === 0 ? (
          <p className="text-center py-4 text-sm text-muted">
            {tr("statsNoSessions")}
          </p>
        ) : (
          <ul className="flex flex-col">
            {recentSessions.map((s) => {
              const timeStr = formatSessionTime(s.completedAt);
              return (
                <li
                  key={s.id}
                  className="flex items-center justify-between border-b border-[var(--hairline)] py-3.5 text-sm first:pt-1 last:border-0 last:pb-1"
                >
                  <div className="flex flex-col gap-1 min-w-0 flex-1 pr-3">
                    <span className="font-semibold text-foreground truncate">
                      {getTaskTitle(s.taskId)}
                    </span>
                    <span className="text-xs text-muted font-mono font-medium">
                      {timeStr}
                    </span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="neo-inset-sm shrink-0 px-2 py-0.5 font-mono font-bold text-accent">
                      {Math.round(s.durationSec / 60)} {tr("minutesShort")}
                    </span>
                    <button
                      type="button"
                      onClick={() => handleDeleteLog(s.id, timeStr)}
                      className="neo-icon-btn shrink-0 p-1.5 text-muted hover:!text-accent"
                      title={tr("deleteRecord")}
                    >
                      <Trash2 size={13} />
                    </button>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}
