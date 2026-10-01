"use client";

import { useEffect, useLayoutEffect, useState } from "react";
import type { Settings } from "@shared/types";
import { applyTheme, runThemeSwitch } from "@/lib/theme";

type ThemeApplierProps = {
  settings: Settings;
  /** False until saved settings are loaded — never paint the defaults over
   *  the theme the boot script already restored. */
  hydrated: boolean;
};

export function ThemeApplier({ settings, hydrated }: ThemeApplierProps) {
  const [prefersDark, setPrefersDark] = useState(
    () =>
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches,
  );

  useEffect(() => {
    const mql = window.matchMedia("(prefers-color-scheme: dark)");
    setPrefersDark(mql.matches);
    // OS light/dark flip while "system" is selected: cross-fade it too.
    const onChange = (e: MediaQueryListEvent) =>
      runThemeSwitch(() => setPrefersDark(e.matches));
    mql.addEventListener("change", onChange);
    return () => mql.removeEventListener("change", onChange);
  }, []);

  // Layout effect: runs inside the same flushSync as a theme switch, so the
  // View Transition snapshot already contains the new theme.
  useLayoutEffect(() => {
    if (!hydrated) return;
    applyTheme(settings, prefersDark);
  }, [settings, prefersDark, hydrated]);

  return null;
}
