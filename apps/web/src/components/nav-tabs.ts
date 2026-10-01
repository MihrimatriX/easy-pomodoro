import { Home, Target, Timer, BarChart3, Settings } from "lucide-react";
import { translate, type MessageKey } from "@shared/i18n/messages";
import type { LocaleId } from "@shared/types";

export type TabId = "home" | "pomodoro" | "habits" | "stats" | "settings";

const TAB_DEFS: {
  id: TabId;
  labelKey: MessageKey;
  /** Fits the 5-slot mobile bar (full labels overlapped on phones). */
  shortKey: MessageKey;
  icon: typeof Home;
}[] = [
  { id: "home", labelKey: "navHome", shortKey: "navHomeShort", icon: Home },
  { id: "pomodoro", labelKey: "navPomodoro", shortKey: "navPomodoro", icon: Timer },
  { id: "habits", labelKey: "navHabits", shortKey: "navHabitsShort", icon: Target },
  { id: "stats", labelKey: "navStats", shortKey: "navStatsShort", icon: BarChart3 },
  { id: "settings", labelKey: "navSettings", shortKey: "navSettings", icon: Settings },
];

export function getNavTabs(locale: LocaleId) {
  return TAB_DEFS.map(({ id, labelKey, shortKey, icon }) => ({
    id,
    label: translate(locale, labelKey),
    shortLabel: translate(locale, shortKey),
    icon,
  }));
}

/** @deprecated use getNavTabs(locale) */
export const NAV_TABS = getNavTabs("tr");
