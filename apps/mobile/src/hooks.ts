import { useCallback, useEffect, useRef, useState } from "react";
import { AppState } from "react-native";
import { createId, getLast7Days, getNextPhase, getPhaseDurationMs, getPhaseDurationSec, getTodayKey, sessionDayKey } from "@shared/pomodoro";
import { toggleHabitCompletion } from "@shared/habits";
import {
  DEFAULT_SETTINGS,
  type Habit,
  type Phase,
  type SessionLog,
  type Settings,
  type Task,
  type TimerStatus,
} from "@shared/types";
import {
  appendSession,
  loadActiveTaskId,
  loadHabits,
  loadSessions,
  loadSettings,
  loadTasks,
  loadTimerState,
  saveActiveTaskId,
  saveHabits,
  saveSessions,
  saveSettings,
  saveTasks,
  saveTimerState,
} from "./storage";

export function useSettings() {
  const [settings, setSettingsState] = useState<Settings>(DEFAULT_SETTINGS);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    void loadSettings().then((next) => {
      setSettingsState(next);
      setHydrated(true);
    });
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    void saveSettings(settings);
  }, [settings, hydrated]);

  const setSettings = useCallback((patch: Partial<Settings>) => {
    setSettingsState((prev) => ({ ...prev, ...patch }));
  }, []);

  return { settings, setSettings, hydrated };
}

export function useTasks() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [activeTaskId, setActiveTaskIdState] = useState<string | null>(null);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    void (async () => {
      const loaded = await loadTasks();
      const savedId = await loadActiveTaskId();
      setTasks(loaded);
      setActiveTaskIdState(
        savedId && loaded.some((task) => task.id === savedId) ? savedId : null,
      );
      setHydrated(true);
    })();
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    void saveTasks(tasks);
  }, [tasks, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    void saveActiveTaskId(activeTaskId);
  }, [activeTaskId, hydrated]);

  const addTask = useCallback((title: string) => {
    const trimmed = title.trim();
    if (!trimmed) return;
    setTasks((prev) => [
      {
        id: createId(),
        title: trimmed,
        completed: false,
        createdAt: new Date().toISOString(),
      },
      ...prev,
    ]);
  }, []);

  const toggleTask = useCallback((id: string) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t)),
    );
  }, []);

  const deleteTask = useCallback((id: string) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
    setActiveTaskIdState((current) => (current === id ? null : current));
  }, []);

  return {
    tasks,
    activeTaskId,
    setActiveTaskId: setActiveTaskIdState,
    addTask,
    toggleTask,
    deleteTask,
  };
}

export function useHabits() {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    void loadHabits().then((next) => {
      setHabits(next);
      setHydrated(true);
    });
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    void saveHabits(habits);
  }, [habits, hydrated]);

  const addHabit = useCallback((title: string) => {
    const trimmed = title.trim();
    if (!trimmed) return;
    setHabits((prev) => [
      {
        id: createId(),
        title: trimmed,
        emoji: "✅",
        completions: [],
        createdAt: new Date().toISOString(),
        targetPerWeek: 7,
      },
      ...prev,
    ]);
  }, []);

  const deleteHabit = useCallback((id: string) => {
    setHabits((prev) => prev.filter((h) => h.id !== id));
  }, []);

  const toggleDate = useCallback((id: string, date = getTodayKey()) => {
    setHabits((prev) =>
      prev.map((h) => (h.id === id ? toggleHabitCompletion(h, date) : h)),
    );
  }, []);

  return { habits, addHabit, deleteHabit, toggleDate };
}

export function useStats() {
  const [sessions, setSessions] = useState<SessionLog[]>([]);

  useEffect(() => {
    void loadSessions().then(setSessions);
  }, []);

  const logSession = useCallback(
    (phase: Phase, durationSec: number, taskId?: string) => {
      if (phase !== "focus") return;
      const session: SessionLog = {
        id: createId(),
        phase,
        durationSec,
        taskId,
        completedAt: new Date().toISOString(),
      };
      void appendSession(session).then(setSessions);
    },
    [],
  );

  const today = getTodayKey();
  const focusSessions = sessions.filter((s) => s.phase === "focus");
  const sessionsToday = focusSessions.filter(
    (s) => sessionDayKey(s.completedAt) === today,
  ).length;
  const totalFocusMinutes = Math.round(
    focusSessions.reduce((sum, s) => sum + s.durationSec, 0) / 60,
  );
  const last7Days = getLast7Days().map((day) => ({
    day,
    count: focusSessions.filter((s) => sessionDayKey(s.completedAt) === day)
      .length,
  }));

  return {
    stats: { sessionsToday, totalFocusMinutes, last7Days, allSessions: sessions },
    logSession,
  };
}

export function usePomodoro(
  settings: Settings,
  onPhaseComplete?: (phase: Phase, durationSec: number) => void,
) {
  const onCompleteRef = useRef(onPhaseComplete);
  const [phase, setPhase] = useState<Phase>("focus");
  const [status, setStatus] = useState<TimerStatus>("idle");
  const [remainingMs, setRemainingMs] = useState(() =>
    getPhaseDurationMs("focus", settings),
  );
  const [pomodoroCount, setPomodoroCount] = useState(0);
  const [ready, setReady] = useState(false);
  const endTimeRef = useRef<number | null>(null);
  const phaseRef = useRef(phase);
  const statusRef = useRef(status);
  const pomodoroCountRef = useRef(pomodoroCount);
  const settingsRef = useRef(settings);

  useEffect(() => {
    onCompleteRef.current = onPhaseComplete;
    phaseRef.current = phase;
    statusRef.current = status;
    pomodoroCountRef.current = pomodoroCount;
    settingsRef.current = settings;
  });

  const persistState = useCallback(
    (
      nextPhase: Phase,
      nextStatus: TimerStatus,
      nextRemainingMs: number,
      nextPomodoroCount: number,
      endTime: number | null,
    ) => {
      void saveTimerState({
        phase: nextPhase,
        status: nextStatus,
        remainingMs: nextRemainingMs,
        pomodoroCount: nextPomodoroCount,
        endTime,
      });
    },
    [],
  );

  const applyPhase = useCallback(
    (nextPhase: Phase, nextPomodoroCount: number, autoStart: boolean) => {
      const duration = getPhaseDurationMs(nextPhase, settingsRef.current);
      phaseRef.current = nextPhase;
      pomodoroCountRef.current = nextPomodoroCount;
      setPhase(nextPhase);
      setPomodoroCount(nextPomodoroCount);
      setRemainingMs(duration);
      if (autoStart) {
        const endTime = Date.now() + duration;
        endTimeRef.current = endTime;
        statusRef.current = "running";
        setStatus("running");
        persistState(nextPhase, "running", duration, nextPomodoroCount, endTime);
      } else {
        endTimeRef.current = null;
        statusRef.current = "idle";
        setStatus("idle");
        persistState(nextPhase, "idle", duration, nextPomodoroCount, null);
      }
    },
    [persistState],
  );

  const completePhase = useCallback(() => {
    const currentPhase = phaseRef.current;
    const currentSettings = settingsRef.current;
    onCompleteRef.current?.(
      currentPhase,
      getPhaseDurationSec(currentPhase, currentSettings),
    );
    const next = getNextPhase(
      currentPhase,
      pomodoroCountRef.current,
      currentSettings,
    );
    applyPhase(next.phase, next.pomodoroCount, currentSettings.autoStart);
  }, [applyPhase]);

  const completePhaseRef = useRef(completePhase);
  useEffect(() => {
    completePhaseRef.current = completePhase;
  });

  useEffect(() => {
    void loadTimerState().then((saved) => {
      if (!saved) {
        setReady(true);
        return;
      }
      setPhase(saved.phase);
      setPomodoroCount(saved.pomodoroCount);
      phaseRef.current = saved.phase;
      pomodoroCountRef.current = saved.pomodoroCount;
      if (saved.status === "running" && saved.endTime) {
        const msLeft = saved.endTime - Date.now();
        if (msLeft <= 0) {
          setRemainingMs(0);
          completePhaseRef.current();
        } else {
          endTimeRef.current = saved.endTime;
          setRemainingMs(msLeft);
          setStatus("running");
          statusRef.current = "running";
        }
      } else {
        setRemainingMs(saved.remainingMs);
        setStatus(saved.status);
        statusRef.current = saved.status;
        endTimeRef.current = saved.endTime;
      }
      setReady(true);
    });
  }, []);

  useEffect(() => {
    if (!ready || statusRef.current !== "idle") return;
    const duration = getPhaseDurationMs(phaseRef.current, settingsRef.current);
    setRemainingMs(duration);
    persistState(
      phaseRef.current,
      "idle",
      duration,
      pomodoroCountRef.current,
      null,
    );
  }, [ready, settings.focusMin, settings.shortBreakMin, settings.longBreakMin, persistState]);

  useEffect(() => {
    if (status !== "running" || !endTimeRef.current) return;
    const tick = () => {
      const msLeft = (endTimeRef.current ?? 0) - Date.now();
      if (msLeft <= 0) {
        setRemainingMs(0);
        completePhase();
        return;
      }
      setRemainingMs(msLeft);
    };
    tick();
    const id = setInterval(tick, 250);
    const sub = AppState.addEventListener("change", (next) => {
      if (next === "active") tick();
    });
    return () => {
      clearInterval(id);
      sub.remove();
    };
  }, [status, completePhase]);

  const start = useCallback(() => {
    const duration =
      remainingMs > 0
        ? remainingMs
        : getPhaseDurationMs(phase, settingsRef.current);
    const endTime = Date.now() + duration;
    endTimeRef.current = endTime;
    setRemainingMs(duration);
    statusRef.current = "running";
    setStatus("running");
    persistState(phase, "running", duration, pomodoroCount, endTime);
  }, [phase, pomodoroCount, remainingMs, persistState]);

  const pause = useCallback(() => {
    if (statusRef.current !== "running") return;
    const msLeft = Math.max(0, (endTimeRef.current ?? Date.now()) - Date.now());
    endTimeRef.current = null;
    setRemainingMs(msLeft);
    statusRef.current = "paused";
    setStatus("paused");
    persistState(phaseRef.current, "paused", msLeft, pomodoroCountRef.current, null);
  }, [persistState]);

  const resume = useCallback(() => {
    if (statusRef.current !== "paused") return;
    const endTime = Date.now() + remainingMs;
    endTimeRef.current = endTime;
    statusRef.current = "running";
    setStatus("running");
    persistState(
      phaseRef.current,
      "running",
      remainingMs,
      pomodoroCountRef.current,
      endTime,
    );
  }, [remainingMs, persistState]);

  const reset = useCallback(() => {
    const duration = getPhaseDurationMs(phaseRef.current, settingsRef.current);
    endTimeRef.current = null;
    setRemainingMs(duration);
    statusRef.current = "idle";
    setStatus("idle");
    persistState(phaseRef.current, "idle", duration, pomodoroCountRef.current, null);
  }, [persistState]);

  const skip = useCallback(() => {
    endTimeRef.current = null;
    const currentSettings = settingsRef.current;
    const next = getNextPhase(
      phaseRef.current,
      pomodoroCountRef.current,
      currentSettings,
      { countFocus: false },
    );
    applyPhase(next.phase, next.pomodoroCount, currentSettings.autoStart);
  }, [applyPhase]);

  return {
    phase,
    status,
    remainingSec: remainingMs / 1000,
    pomodoroCount,
    progress:
      getPhaseDurationMs(phase, settings) > 0
        ? 1 - remainingMs / getPhaseDurationMs(phase, settings)
        : 0,
    start,
    pause,
    resume,
    reset,
    skip,
  };
}
