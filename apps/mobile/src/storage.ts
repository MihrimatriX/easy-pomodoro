import AsyncStorage from "@react-native-async-storage/async-storage";
import { normalizeSettings } from "@shared/settings";
import {
  STORAGE_KEYS,
  type Habit,
  type PersistedTimerState,
  type SessionLog,
  type Settings,
  type Task,
} from "@shared/types";

async function readJson<T>(key: string, fallback: T): Promise<T> {
  try {
    const raw = await AsyncStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

async function writeJson<T>(key: string, value: T): Promise<void> {
  await AsyncStorage.setItem(key, JSON.stringify(value));
}

export async function loadSettings(): Promise<Settings> {
  return normalizeSettings(await readJson(STORAGE_KEYS.settings, {}));
}

export async function saveSettings(settings: Settings): Promise<void> {
  await writeJson(STORAGE_KEYS.settings, settings);
}

export async function loadTasks(): Promise<Task[]> {
  return readJson<Task[]>(STORAGE_KEYS.tasks, []);
}

export async function saveTasks(tasks: Task[]): Promise<void> {
  await writeJson(STORAGE_KEYS.tasks, tasks);
}

export async function loadHabits(): Promise<Habit[]> {
  return readJson<Habit[]>(STORAGE_KEYS.habits, []);
}

export async function saveHabits(habits: Habit[]): Promise<void> {
  await writeJson(STORAGE_KEYS.habits, habits);
}

export async function loadSessions(): Promise<SessionLog[]> {
  return readJson<SessionLog[]>(STORAGE_KEYS.sessions, []);
}

export async function saveSessions(sessions: SessionLog[]): Promise<void> {
  await writeJson(STORAGE_KEYS.sessions, sessions);
}

export async function appendSession(
  session: SessionLog,
): Promise<SessionLog[]> {
  const sessions = [...(await loadSessions()), session];
  await saveSessions(sessions);
  return sessions;
}

export async function loadTimerState(): Promise<PersistedTimerState | null> {
  return readJson<PersistedTimerState | null>(STORAGE_KEYS.timer, null);
}

export async function saveTimerState(
  state: PersistedTimerState | null,
): Promise<void> {
  if (state === null) {
    await AsyncStorage.removeItem(STORAGE_KEYS.timer);
    return;
  }
  await writeJson(STORAGE_KEYS.timer, state);
}

export async function loadActiveTaskId(): Promise<string | null> {
  const id = await readJson<string | null>(STORAGE_KEYS.activeTask, null);
  return typeof id === "string" && id ? id : null;
}

export async function saveActiveTaskId(id: string | null): Promise<void> {
  if (!id) {
    await AsyncStorage.removeItem(STORAGE_KEYS.activeTask);
    return;
  }
  await writeJson(STORAGE_KEYS.activeTask, id);
}
