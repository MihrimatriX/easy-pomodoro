import type { ColorThemeId, Settings } from "./types";

export type ThemeSurface = {
  background: string;
  gradient: [string, string, string];
  neoBg: string;
  shadowLight: string;
  shadowDark: string;
  foreground: string;
  muted: string;
  border: string;
  glassBg: string;
  glassBorder: string;
};

export type ThemePalette = {
  id: ColorThemeId;
  label: string;
  swatch: string;
  accent: string;
  accentHover: string;
  focus: string;
  shortBreak: string;
  longBreak: string;
  surface: ThemeSurface;
};

function surface(
  neoBg: string,
  shadowLight: string,
  shadowDark: string,
  foreground: string,
  muted: string,
  border: string,
  gradient: [string, string, string],
  glassTint: string,
): ThemeSurface {
  return {
    background: neoBg,
    gradient,
    neoBg,
    shadowLight,
    shadowDark,
    foreground,
    muted,
    border,
    glassBg: glassTint,
    glassBorder: "rgba(255, 255, 255, 0.55)",
  };
}

export const COLOR_THEMES: ThemePalette[] = [
  {
    id: "ocean",
    label: "Okyanus",
    swatch: "#2563eb",
    accent: "#2563eb",
    accentHover: "#3b82f6",
    focus: "#2563eb",
    shortBreak: "#14b8a6",
    longBreak: "#6366f1",
    surface: surface(
      "#e8eef8",
      "#f5f8fc",
      "#b8c4d8",
      "#152a45",
      "#4a5c72",
      "#c5d0e4",
      ["#eef3fb", "#e0e9f8", "#dce6f7"],
      "rgba(255, 255, 255, 0.42)",
    ),
  },
  {
    id: "tomato",
    label: "Domates",
    swatch: "#e63946",
    accent: "#e63946",
    accentHover: "#ef476f",
    focus: "#e63946",
    shortBreak: "#2a9d8f",
    longBreak: "#e76f51",
    surface: surface(
      "#f5ecec",
      "#faf6f6",
      "#d4b8b8",
      "#3d1f1f",
      "#6b4f4f",
      "#e0c8c8",
      ["#faf3f3", "#f5e8e8", "#f0dede"],
      "rgba(255, 248, 248, 0.45)",
    ),
  },
  {
    id: "forest",
    label: "Orman",
    swatch: "#2d6a4f",
    accent: "#2d6a4f",
    accentHover: "#40916c",
    focus: "#2d6a4f",
    shortBreak: "#52b788",
    longBreak: "#1b4332",
    surface: surface(
      "#e8f0ec",
      "#f4f9f6",
      "#b8cfc4",
      "#1a3328",
      "#4a6358",
      "#c5d9ce",
      ["#eef6f1", "#e3efe8", "#d9ebe3"],
      "rgba(248, 255, 252, 0.44)",
    ),
  },
  {
    id: "violet",
    label: "Menekşe",
    swatch: "#7c3aed",
    accent: "#7c3aed",
    accentHover: "#8b5cf6",
    focus: "#7c3aed",
    shortBreak: "#a78bfa",
    longBreak: "#5b21b6",
    surface: surface(
      "#eeeaf8",
      "#f7f4fd",
      "#c4b8dc",
      "#2a1f45",
      "#5c4f72",
      "#d0c5e4",
      ["#f3effb", "#ebe4f8", "#e4dcf5"],
      "rgba(252, 250, 255, 0.46)",
    ),
  },
  {
    id: "amber",
    label: "Kehribar",
    swatch: "#d97706",
    accent: "#d97706",
    accentHover: "#f59e0b",
    focus: "#d97706",
    shortBreak: "#84cc16",
    longBreak: "#b45309",
    surface: surface(
      "#f5f0e8",
      "#faf7f2",
      "#d4c4a8",
      "#3d2e1a",
      "#6b5a42",
      "#e0d0b8",
      ["#faf6ef", "#f5ede0", "#f0e5d4"],
      "rgba(255, 252, 245, 0.48)",
    ),
  },
  {
    id: "rose",
    label: "Gül",
    swatch: "#e11d48",
    accent: "#e11d48",
    accentHover: "#f43f5e",
    focus: "#e11d48",
    shortBreak: "#fb7185",
    longBreak: "#be123c",
    surface: surface(
      "#f5eaee",
      "#faf4f6",
      "#d4b8c0",
      "#3d1f28",
      "#6b4f58",
      "#e0c8d0",
      ["#faf2f5", "#f5e8ed", "#f0dee5"],
      "rgba(255, 248, 250, 0.46)",
    ),
  },
];

export function isValidHexColor(value: string): boolean {
  return /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/.test(value);
}

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const normalized = hex.replace("#", "");
  const full =
    normalized.length === 3
      ? normalized
          .split("")
          .map((c) => c + c)
          .join("")
      : normalized;
  if (full.length !== 6) return null;
  const n = parseInt(full, 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

export function accentRgba(hex: string, alpha: number): string {
  const rgb = hexToRgb(hex);
  if (!rgb) return `rgba(37, 99, 235, ${alpha})`;
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`;
}

function buildCustomTheme(accent: string): ThemePalette {
  const hover = accent;
  return {
    id: "custom",
    label: "Özel",
    swatch: accent,
    accent,
    accentHover: hover,
    focus: accent,
    shortBreak: "#14b8a6",
    longBreak: "#6366f1",
    surface: surface(
      "#eaeef5",
      "#f6f8fc",
      "#bcc4d4",
      "#152a45",
      "#4a5c72",
      "#c5d0e4",
      ["#eef2f9", "#e4eaf5", "#dce3f0"],
      "rgba(255, 255, 255, 0.44)",
    ),
  };
}

export function getThemePalette(settings: Settings): ThemePalette {
  if (settings.colorTheme === "custom") {
    const accent = isValidHexColor(settings.customAccent)
      ? settings.customAccent
      : "#6366f1";
    return buildCustomTheme(accent);
  }
  return (
    COLOR_THEMES.find((t) => t.id === settings.colorTheme) ?? COLOR_THEMES[0]
  );
}

export const SURFACE_LIGHT = COLOR_THEMES[0].surface;
export const SURFACE_DARK = SURFACE_LIGHT;
