export type Phase = "focus" | "shortBreak" | "longBreak";

export type TimerStatus = "idle" | "running" | "paused";

export type ThemeMode = "system" | "light" | "dark";

export type ColorThemeId =
  | "tomato"
  | "forest"
  | "ocean"
  | "violet"
  | "amber"
  | "rose"
  | "custom";

export type UiStyleId = "neo" | "glass" | "clay" | "skeuo" | "liquid" | "flat";

export type LocaleId = "tr" | "en";

export type Settings = {
  focusMin: number;
  shortBreakMin: number;
  longBreakMin: number;
  longBreakInterval: number;
  autoStart: boolean;
  sound: boolean;
  notifications: boolean;
  theme: ThemeMode;
  colorTheme: ColorThemeId;
  customAccent: string;
  uiStyle: UiStyleId;
  locale: LocaleId;
  soundType?: "chime" | "digital" | "bird" | "gong";
};

export type Task = {
  id: string;
  title: string;
  completed: boolean;
  createdAt: string;
  estimatedPomodoros?: number;
};

export type Habit = {
  id: string;
  title: string;
  emoji: string;
  completions: string[];
  createdAt: string;
  /** Haftalık hedef (1–7), varsayılan 7 = her gün */
  targetPerWeek?: number;
};

export type SessionLog = {
  id: string;
  phase: Phase;
  durationSec: number;
  taskId?: string;
  completedAt: string;
};

export type PersistedTimerState = {
  phase: Phase;
  status: TimerStatus;
  remainingMs: number;
  pomodoroCount: number;
  endTime: number | null;
};

export const DEFAULT_SETTINGS: Settings = {
  focusMin: 25,
  shortBreakMin: 5,
  longBreakMin: 15,
  longBreakInterval: 4,
  autoStart: true,
  sound: true,
  notifications: true,
  theme: "light",
  colorTheme: "ocean",
  customAccent: "#6366f1",
  uiStyle: "neo",
  locale: "tr",
  soundType: "chime",
};

export const STORAGE_KEYS = {
  settings: "easy-pomodoro:settings",
  tasks: "easy-pomodoro:tasks",
  habits: "easy-pomodoro:habits",
  sessions: "easy-pomodoro:sessions",
  timer: "easy-pomodoro:timer",
  activeTask: "easy-pomodoro:active-task",
} as const;
