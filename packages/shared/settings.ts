import { normalizeUiStyle } from "./ui-styles";
import { DEFAULT_SETTINGS, type LocaleId, type Settings } from "./types";

export type LegacySettings = Partial<Settings> & { surfaceBlend?: number };

export function normalizeLocale(value: unknown): LocaleId {
  return value === "en" ? "en" : "tr";
}

export function normalizeSettings(saved: LegacySettings): Settings {
  const merged = { ...DEFAULT_SETTINGS, ...saved };
  merged.uiStyle = normalizeUiStyle(saved.uiStyle, saved.surfaceBlend);
  merged.locale = normalizeLocale(saved.locale);
  return merged;
}
