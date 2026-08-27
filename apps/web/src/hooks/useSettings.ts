"use client";

import { useCallback, useEffect, useState } from "react";
import { DEFAULT_SETTINGS, type Settings } from "@shared/types";
import { loadSettings, saveSettings } from "@/lib/storage";

export function useSettings() {
  const [settings, setSettingsState] = useState<Settings>(DEFAULT_SETTINGS);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setSettingsState(loadSettings());
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    saveSettings(settings);
  }, [settings, hydrated]);

  const setSettings = useCallback((patch: Partial<Settings>) => {
    setSettingsState((prev) => ({ ...prev, ...patch }));
  }, []);

  const updateSettings = useCallback((next: Settings) => {
    setSettingsState(next);
  }, []);

  return { settings, setSettings, updateSettings, hydrated };
}
