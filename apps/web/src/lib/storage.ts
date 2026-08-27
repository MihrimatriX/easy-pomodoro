import { normalizeSettings, type LegacySettings } from "@shared/settings";
import {
  STORAGE_KEYS,
  type PersistedTimerState,
  type SessionLog,
  type Settings,
  type Task,
  type Habit,
} from "@shared/types";

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

function readJson<T>(key: string, fallback: T): T {
  if (!isBrowser()) return fallback;
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function writeJson<T>(key: string, value: T): void {
  if (!isBrowser()) return;
  localStorage.setItem(key, JSON.stringify(value));
}

export function loadSettings(): Settings {
  const saved = readJson<LegacySettings>(STORAGE_KEYS.settings, {});
  return normalizeSettings(saved);
}

export function saveSettings(settings: Settings): void {
  writeJson(STORAGE_KEYS.settings, settings);
}

export function loadTasks(): Task[] {
  return readJson<Task[]>(STORAGE_KEYS.tasks, []);
}

export function saveTasks(tasks: Task[]): void {
  writeJson(STORAGE_KEYS.tasks, tasks);
}

export function loadHabits(): Habit[] {
  return readJson<Habit[]>(STORAGE_KEYS.habits, []);
}

export function saveHabits(habits: Habit[]): void {
  writeJson(STORAGE_KEYS.habits, habits);
}

export function loadSessions(): SessionLog[] {
  return readJson<SessionLog[]>(STORAGE_KEYS.sessions, []);
}

export function saveSessions(sessions: SessionLog[]): void {
  writeJson(STORAGE_KEYS.sessions, sessions);
}

export function appendSession(session: SessionLog): SessionLog[] {
  const sessions = [...loadSessions(), session];
  saveSessions(sessions);
  return sessions;
}

export function loadTimerState(): PersistedTimerState | null {
  return readJson<PersistedTimerState | null>(STORAGE_KEYS.timer, null);
}

export function saveTimerState(state: PersistedTimerState | null): void {
  if (state === null) {
    if (isBrowser()) localStorage.removeItem(STORAGE_KEYS.timer);
    return;
  }
  writeJson(STORAGE_KEYS.timer, state);
}

export function loadActiveTaskId(): string | null {
  const id = readJson<string | null>(STORAGE_KEYS.activeTask, null);
  return typeof id === "string" && id ? id : null;
}

export function saveActiveTaskId(id: string | null): void {
  if (!isBrowser()) return;
  if (!id) {
    localStorage.removeItem(STORAGE_KEYS.activeTask);
    return;
  }
  writeJson(STORAGE_KEYS.activeTask, id);
}

export type BackupPayload = {
  version: 1;
  exportedAt: string;
  settings: Settings;
  tasks: Task[];
  habits: Habit[];
  sessions: SessionLog[];
  timer: PersistedTimerState | null;
  activeTaskId: string | null;
};

export function exportBackup(): BackupPayload {
  return {
    version: 1,
    exportedAt: new Date().toISOString(),
    settings: loadSettings(),
    tasks: loadTasks(),
    habits: loadHabits(),
    sessions: loadSessions(),
    timer: loadTimerState(),
    activeTaskId: loadActiveTaskId(),
  };
}

export function importBackup(raw: unknown): boolean {
  if (!raw || typeof raw !== "object") return false;
  const data = raw as Partial<BackupPayload>;
  if (data.version !== 1) return false;
  if (!Array.isArray(data.tasks) || !Array.isArray(data.habits) || !Array.isArray(data.sessions)) {
    return false;
  }
  saveSettings(normalizeSettings((data.settings ?? {}) as LegacySettings));
  saveTasks(data.tasks);
  saveHabits(data.habits);
  saveSessions(data.sessions);
  saveTimerState(data.timer ?? null);
  saveActiveTaskId(data.activeTaskId ?? null);
  return true;
}

export function clearAllData(): void {
  if (!isBrowser()) return;
  for (const key of Object.values(STORAGE_KEYS)) {
    localStorage.removeItem(key);
  }
}
