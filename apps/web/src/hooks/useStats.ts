"use client";

import { useCallback, useEffect, useState } from "react";
import { createId, getLast7Days, getTodayKey, sessionDayKey } from "@shared/pomodoro";
import type { Phase, SessionLog } from "@shared/types";
import { appendSession, loadSessions, saveSessions } from "@/lib/storage";

function computeStats(sessions: SessionLog[]) {
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
  return { sessionsToday, totalFocusMinutes, last7Days, allSessions: sessions };
}

export function useStats() {
  const [sessions, setSessions] = useState<SessionLog[]>([]);

  useEffect(() => {
    setSessions(loadSessions());
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
      const next = appendSession(session);
      setSessions(next);
    },
    [],
  );

  const deleteSession = useCallback((id: string) => {
    setSessions((prev) => {
      const next = prev.filter((s) => s.id !== id);
      saveSessions(next);
      return next;
    });
  }, []);

  const stats = computeStats(sessions);

  return {
    stats,
    logSession,
    deleteSession,
    refresh: () => setSessions(loadSessions()),
  };
}
