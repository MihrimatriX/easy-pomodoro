"use client";

import { useEffect, useState } from "react";
import { accentRgba, getThemePalette } from "@shared/themes";
import { getUiSurface, resolveMode } from "@shared/ui-surfaces";
import type { Settings, UiStyleId } from "@shared/types";

const AMBIENT_BY_STYLE: Record<UiStyleId, number> = {
  neo: 0.14,
  glass: 0.22,
  clay: 0.06,
  skeuo: 0.04,
  liquid: 0.28,
  flat: 0.04,
};

function withAlpha(color: string, alpha: number): string {
  const rgba = color.match(
    /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)/,
  );
  if (rgba) return `rgba(${rgba[1]}, ${rgba[2]}, ${rgba[3]}, ${alpha})`;
  return accentRgba(color, alpha);
}

export function ThemeApplier({ settings }: { settings: Settings }) {
  const [prefersDark, setPrefersDark] = useState(false);

  useEffect(() => {
    const mql = window.matchMedia("(prefers-color-scheme: dark)");
    setPrefersDark(mql.matches);
    const onChange = (e: MediaQueryListEvent) => setPrefersDark(e.matches);
    mql.addEventListener("change", onChange);
    return () => mql.removeEventListener("change", onChange);
  }, []);

  useEffect(() => {
    const palette = getThemePalette(settings);
    const mode = resolveMode(settings.theme, prefersDark);
    const s = getUiSurface(settings.uiStyle, mode, palette.accent);
    const root = document.documentElement;
    const dark = mode === "dark";
    const glassy =
      settings.uiStyle === "glass" || settings.uiStyle === "liquid";

    root.style.setProperty("--background", s.background);
    root.style.setProperty("--foreground", s.foreground);
    root.style.setProperty("--card", s.surface);
    root.style.setProperty("--input-bg", s.inputBg);
    root.style.setProperty("--muted", s.muted);
    root.style.setProperty("--border", s.border);
    root.style.setProperty("--accent", palette.accent);
    root.style.setProperty("--accent-hover", palette.accentHover);
    root.style.setProperty("--phase-focus", palette.focus);
    root.style.setProperty("--phase-short", palette.shortBreak);
    root.style.setProperty("--phase-long", palette.longBreak);
    root.style.setProperty("--neo-bg", s.surface);
    root.style.setProperty("--shadow-light", s.shadowLight);
    root.style.setProperty("--shadow-dark", s.shadowDark);
    root.style.setProperty("--neo-light", s.shadowLight);
    root.style.setProperty("--neo-dark", s.shadowDark);
    root.style.setProperty("--neo-light-sm", withAlpha(s.shadowLight, 0.72));
    root.style.setProperty("--neo-dark-sm", withAlpha(s.shadowDark, 0.55));
    root.style.setProperty("--glass-bg", s.glassBg);
    root.style.setProperty("--glass-border", s.glassBorder);
    root.style.setProperty("--bg-grad-0", s.gradient[0]);
    root.style.setProperty("--bg-grad-1", s.gradient[1]);
    root.style.setProperty("--bg-grad-2", s.gradient[2]);
    root.style.setProperty(
      "--neo-accent-glow",
      accentRgba(palette.accent, 0.28),
    );
    root.style.setProperty(
      "--neo-accent-dark",
      accentRgba(palette.accent, 0.35),
    );
    root.style.setProperty(
      "--ambient-opacity",
      String(AMBIENT_BY_STYLE[settings.uiStyle]),
    );

    root.style.setProperty("--ui-radius-lg", `${s.traits.radiusLg}px`);
    root.style.setProperty("--ui-radius-md", `${s.traits.radiusMd}px`);
    root.style.setProperty("--ui-radius-sm", `${s.traits.radiusSm}px`);

    if (glassy) {
      root.style.setProperty(
        "--highlight",
        dark ? "rgba(255,255,255,0.2)" : "rgba(255,255,255,0.78)",
      );
      root.style.setProperty(
        "--highlight-soft",
        dark ? "rgba(255,255,255,0.1)" : "rgba(255,255,255,0.45)",
      );
      root.style.setProperty(
        "--shade",
        dark ? "rgba(0,0,0,0.48)" : "rgba(15,23,42,0.14)",
      );
      root.style.setProperty(
        "--shade-strong",
        dark ? "rgba(0,0,0,0.62)" : "rgba(15,23,42,0.22)",
      );
      root.style.setProperty(
        "--text-emboss",
        dark ? "none" : "0 1px 0 rgba(255,255,255,0.45)",
      );
    } else if (settings.uiStyle === "skeuo") {
      root.style.setProperty(
        "--highlight",
        dark ? "rgba(255,255,255,0.32)" : "rgba(255,255,255,0.92)",
      );
      root.style.setProperty(
        "--highlight-soft",
        dark ? "rgba(255,255,255,0.16)" : "rgba(255,255,255,0.55)",
      );
      root.style.setProperty(
        "--shade",
        dark ? "rgba(0,0,0,0.5)" : "rgba(15,23,42,0.22)",
      );
      root.style.setProperty(
        "--shade-strong",
        dark ? "rgba(0,0,0,0.68)" : "rgba(15,23,42,0.34)",
      );
      root.style.setProperty(
        "--text-emboss",
        dark
          ? "0 1px 0 rgba(0,0,0,0.55)"
          : "0 1px 0 rgba(255,255,255,0.5)",
      );
    } else {
      root.style.setProperty(
        "--highlight",
        dark ? withAlpha(s.shadowLight, 0.85) : "rgba(255,255,255,0.82)",
      );
      root.style.setProperty(
        "--highlight-soft",
        dark ? withAlpha(s.shadowLight, 0.45) : "rgba(255,255,255,0.4)",
      );
      root.style.setProperty(
        "--shade",
        dark ? "rgba(0,0,0,0.42)" : "rgba(15,23,42,0.16)",
      );
      root.style.setProperty(
        "--shade-strong",
        dark ? "rgba(0,0,0,0.58)" : "rgba(15,23,42,0.28)",
      );
      root.style.setProperty(
        "--text-emboss",
        dark
          ? "0 1px 0 rgba(0,0,0,0.45)"
          : "0 1px 0 rgba(255,255,255,0.55)",
      );
    }

    root.style.setProperty("--knob", dark ? s.foreground : "#ffffff");
    root.style.setProperty("--hairline", s.border);
    root.style.colorScheme = mode;

    root.dataset.colorTheme = settings.colorTheme;
    root.dataset.uiStyle = settings.uiStyle;
    root.dataset.theme = mode;
    root.lang = settings.locale;

    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", s.background);
  }, [settings, prefersDark]);

  return null;
}
