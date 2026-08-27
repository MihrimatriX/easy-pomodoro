"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  getNextPhase,
  getPhaseDurationMs,
  getPhaseDurationSec,
} from "@shared/pomodoro";
import type { Phase, Settings, TimerStatus } from "@shared/types";
import { loadTimerState, saveTimerState } from "@/lib/storage";

type PomodoroCallbacks = {
  onPhaseComplete?: (completedPhase: Phase, durationSec: number) => void;
  onNotify?: (completedPhase: Phase) => void;
  onSound?: (soundType?: "chime" | "digital" | "bird" | "gong") => void;
};

export function usePomodoro(
  settings: Settings,
  callbacks: PomodoroCallbacks = {},
) {
  const callbacksRef = useRef(callbacks);

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
  const completePhaseRef = useRef<() => void>(() => {});

  useEffect(() => {
    callbacksRef.current = callbacks;
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
      saveTimerState({
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
        persistState(
          nextPhase,
          "running",
          duration,
          nextPomodoroCount,
          endTime,
        );
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
    const durationSec = getPhaseDurationSec(currentPhase, currentSettings);

    callbacksRef.current.onPhaseComplete?.(currentPhase, durationSec);

    if (currentSettings.notifications) {
      callbacksRef.current.onNotify?.(currentPhase);
    }
    if (currentSettings.sound) {
      callbacksRef.current.onSound?.(currentSettings.soundType);
    }

    const { phase: nextPhase, pomodoroCount: nextCount } = getNextPhase(
      currentPhase,
      pomodoroCountRef.current,
      currentSettings,
    );

    applyPhase(nextPhase, nextCount, currentSettings.autoStart);
  }, [applyPhase]);

  useEffect(() => {
    completePhaseRef.current = completePhase;
  });

  useEffect(() => {
    const saved = loadTimerState();
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
  }, []);

  useEffect(() => {
    if (!ready || statusRef.current !== "idle") return;
    const nextPhase = phaseRef.current;
    const duration = getPhaseDurationMs(nextPhase, settingsRef.current);
    setRemainingMs(duration);
    persistState(nextPhase, "idle", duration, pomodoroCountRef.current, null);
  }, [
    ready,
    settings.focusMin,
    settings.shortBreakMin,
    settings.longBreakMin,
    persistState,
  ]);

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

    const handleVisibilityChange = () => {
      if (document.visibilityState === "visible") {
        tick();
      }
    };

    tick();
    const id = window.setInterval(tick, 250);
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => {
      window.clearInterval(id);
      document.removeEventListener("visibilitychange", handleVisibilityChange);
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
    persistState(
      phaseRef.current,
      "paused",
      msLeft,
      pomodoroCountRef.current,
      null,
    );
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
    persistState(
      phaseRef.current,
      "idle",
      duration,
      pomodoroCountRef.current,
      null,
    );
  }, [persistState]);

  const skip = useCallback(() => {
    endTimeRef.current = null;
    const currentSettings = settingsRef.current;
    const { phase: nextPhase, pomodoroCount: nextCount } = getNextPhase(
      phaseRef.current,
      pomodoroCountRef.current,
      currentSettings,
      { countFocus: false },
    );
    applyPhase(nextPhase, nextCount, currentSettings.autoStart);
  }, [applyPhase]);

  const selectPhase = useCallback(
    (nextPhase: Phase) => {
      endTimeRef.current = null;
      applyPhase(nextPhase, pomodoroCountRef.current, false);
    },
    [applyPhase],
  );

  const totalMs = getPhaseDurationMs(phase, settings);
  const progress = totalMs > 0 ? 1 - remainingMs / totalMs : 0;

  return {
    phase,
    status,
    remainingMs,
    remainingSec: remainingMs / 1000,
    pomodoroCount,
    progress,
    start,
    pause,
    resume,
    reset,
    skip,
    selectPhase,
  };
}
