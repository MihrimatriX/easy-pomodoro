import { flushSync } from "react-dom";
import { accentRgba, getThemePalette } from "@shared/themes";
import { getUiSurface, resolveMode, type UiMode } from "@shared/ui-surfaces";
import type { Settings, UiStyleId } from "@shared/types";
import { THEME_CACHE_KEY } from "@/lib/theme-boot";

/**
 * Theme = CSS custom properties + a few `data-*` attributes on <html>.
 *
 * The same resolved snapshot is (1) applied by <ThemeApplier>, (2) cached in
 * localStorage and (3) re-applied by an inline boot script before the first
 * paint, so a reload never flashes the default neo theme first.
 */

export type ResolvedTheme = {
  mode: UiMode;
  uiStyle: UiStyleId;
  colorTheme: string;
  lang: string;
  vars: Record<string, string>;
};

type ThemeCache = {
  /** Settings.theme — "system" picks light/dark at boot via matchMedia. */
  pref: Settings["theme"];
  light?: ResolvedTheme;
  dark?: ResolvedTheme;
};

const AMBIENT_BY_STYLE: Record<UiStyleId, number> = {
  neo: 0.14,
  glass: 0.22,
  clay: 0.06,
  skeuo: 0.04,
  liquid: 0.28,
  flat: 0.04,
};

function withAlpha(color: string, alpha: number): string {
  const rgba = color.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)/);
  if (rgba) return `rgba(${rgba[1]}, ${rgba[2]}, ${rgba[3]}, ${alpha})`;
  return accentRgba(color, alpha);
}

export function resolveTheme(settings: Settings, mode: UiMode): ResolvedTheme {
  const palette = getThemePalette(settings);
  const s = getUiSurface(settings.uiStyle, mode, palette.accent);
  const dark = mode === "dark";
  const glassy = settings.uiStyle === "glass" || settings.uiStyle === "liquid";

  const vars: Record<string, string> = {
    "--background": s.background,
    "--foreground": s.foreground,
    "--card": s.surface,
    "--input-bg": s.inputBg,
    "--muted": s.muted,
    "--border": s.border,
    "--accent": palette.accent,
    "--accent-hover": palette.accentHover,
    "--phase-focus": palette.focus,
    "--phase-short": palette.shortBreak,
    "--phase-long": palette.longBreak,
    "--neo-bg": s.surface,
    "--shadow-light": s.shadowLight,
    "--shadow-dark": s.shadowDark,
    "--neo-light": s.shadowLight,
    "--neo-dark": s.shadowDark,
    "--neo-light-sm": withAlpha(s.shadowLight, 0.72),
    "--neo-dark-sm": withAlpha(s.shadowDark, 0.55),
    "--glass-bg": s.glassBg,
    "--glass-border": s.glassBorder,
    "--bg-grad-0": s.gradient[0],
    "--bg-grad-1": s.gradient[1],
    "--bg-grad-2": s.gradient[2],
    "--neo-accent-glow": accentRgba(palette.accent, 0.28),
    "--neo-accent-dark": accentRgba(palette.accent, 0.35),
    "--ambient-opacity": String(AMBIENT_BY_STYLE[settings.uiStyle]),
    "--ui-radius-lg": `${s.traits.radiusLg}px`,
    "--ui-radius-md": `${s.traits.radiusMd}px`,
    "--ui-radius-sm": `${s.traits.radiusSm}px`,
    "--knob": dark ? s.foreground : "#ffffff",
    "--hairline": s.border,
  };

  if (glassy) {
    Object.assign(vars, {
      "--highlight": dark ? "rgba(255,255,255,0.2)" : "rgba(255,255,255,0.78)",
      "--highlight-soft": dark ? "rgba(255,255,255,0.1)" : "rgba(255,255,255,0.45)",
      "--shade": dark ? "rgba(0,0,0,0.48)" : "rgba(15,23,42,0.14)",
      "--shade-strong": dark ? "rgba(0,0,0,0.62)" : "rgba(15,23,42,0.22)",
      "--text-emboss": dark ? "none" : "0 1px 0 rgba(255,255,255,0.45)",
    });
  } else if (settings.uiStyle === "skeuo") {
    Object.assign(vars, {
      "--highlight": dark ? "rgba(255,255,255,0.32)" : "rgba(255,255,255,0.92)",
      "--highlight-soft": dark ? "rgba(255,255,255,0.16)" : "rgba(255,255,255,0.55)",
      "--shade": dark ? "rgba(0,0,0,0.5)" : "rgba(15,23,42,0.22)",
      "--shade-strong": dark ? "rgba(0,0,0,0.68)" : "rgba(15,23,42,0.34)",
      "--text-emboss": dark ? "0 1px 0 rgba(0,0,0,0.55)" : "0 1px 0 rgba(255,255,255,0.5)",
    });
  } else {
    Object.assign(vars, {
      "--highlight": dark ? withAlpha(s.shadowLight, 0.85) : "rgba(255,255,255,0.82)",
      "--highlight-soft": dark ? withAlpha(s.shadowLight, 0.45) : "rgba(255,255,255,0.4)",
      "--shade": dark ? "rgba(0,0,0,0.42)" : "rgba(15,23,42,0.16)",
      "--shade-strong": dark ? "rgba(0,0,0,0.58)" : "rgba(15,23,42,0.28)",
      "--text-emboss": dark ? "0 1px 0 rgba(0,0,0,0.45)" : "0 1px 0 rgba(255,255,255,0.55)",
    });
  }

  return {
    mode,
    uiStyle: settings.uiStyle,
    colorTheme: settings.colorTheme,
    lang: settings.locale,
    vars,
  };
}

export function applyResolvedTheme(t: ResolvedTheme, root = document.documentElement) {
  for (const [name, value] of Object.entries(t.vars)) {
    root.style.setProperty(name, value);
  }
  root.style.colorScheme = t.mode;
  root.dataset.colorTheme = t.colorTheme;
  root.dataset.uiStyle = t.uiStyle;
  root.dataset.theme = t.mode;
  root.lang = t.lang;
  // Next renders one theme-color meta per media query; keep all in sync.
  document
    .querySelectorAll('meta[name="theme-color"]')
    .forEach((m) => m.setAttribute("content", t.vars["--background"]));
}

/** Applies the theme for `settings` and refreshes the boot cache. */
export function applyTheme(settings: Settings, prefersDark: boolean) {
  const mode = resolveMode(settings.theme, prefersDark);
  const current = resolveTheme(settings, mode);
  applyResolvedTheme(current);

  const cache: ThemeCache = { pref: settings.theme };
  if (settings.theme === "system") {
    cache.light = mode === "light" ? current : resolveTheme(settings, "light");
    cache.dark = mode === "dark" ? current : resolveTheme(settings, "dark");
  } else {
    cache[mode] = current;
  }
  try {
    localStorage.setItem(THEME_CACHE_KEY, JSON.stringify(cache));
  } catch {
    // Private mode / quota: the app still themes itself after hydration.
  }
}

// ───────────────────────── switching ─────────────────────────

type ViewTransitionLike = { finished: Promise<void> };
type DocumentWithVT = Document & {
  startViewTransition?: (cb: () => void) => ViewTransitionLike;
};

export type ThemeSwitchOrigin = { x: number; y: number } | null;

/** Centre of the clicked control, used as the reveal origin. */
export function originFromEvent(
  event?: { currentTarget: EventTarget | null } | null,
): ThemeSwitchOrigin {
  const el = event?.currentTarget;
  if (!(el instanceof Element)) return null;
  const r = el.getBoundingClientRect();
  return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
}

/**
 * Runs a theme-changing state update as one atomic visual step.
 *
 * Gradients, inset ↔ outset shadows and backdrop-filter cannot be
 * interpolated by per-element CSS transitions, so switching neo ↔ glass ↔
 * skeuo used to show half-snapped surfaces. Instead we:
 *  - disable element transitions for the duration of the switch, and
 *  - when the View Transitions API exists, snapshot the old page and reveal
 *    the new one (circle from the clicked control, else a cross-fade).
 */
export function runThemeSwitch(update: () => void, origin: ThemeSwitchOrigin = null) {
  const root = document.documentElement;
  const doc = document as DocumentWithVT;
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  root.classList.add("theme-switching");
  const done = () => root.classList.remove("theme-switching", "vt-reveal", "vt-fade");

  if (!doc.startViewTransition || reduceMotion) {
    flushSync(update);
    // Two frames: let the new styles paint before transitions come back.
    requestAnimationFrame(() => requestAnimationFrame(done));
    return;
  }

  if (origin) {
    const radius = Math.hypot(
      Math.max(origin.x, window.innerWidth - origin.x),
      Math.max(origin.y, window.innerHeight - origin.y),
    );
    root.style.setProperty("--vt-x", `${origin.x}px`);
    root.style.setProperty("--vt-y", `${origin.y}px`);
    root.style.setProperty("--vt-r", `${Math.ceil(radius)}px`);
    root.classList.add("vt-reveal");
  } else {
    root.classList.add("vt-fade");
  }

  const transition = doc.startViewTransition(() => flushSync(update));
  transition.finished.finally(done);
}
