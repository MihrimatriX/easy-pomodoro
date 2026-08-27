import { Home, Target, Timer, BarChart3, Settings } from "lucide-react";
import { translate, type MessageKey } from "@shared/i18n/messages";
import type { LocaleId } from "@shared/types";

export type TabId = "home" | "pomodoro" | "habits" | "stats" | "settings";

const TAB_DEFS: { id: TabId; labelKey: MessageKey; icon: typeof Home }[] = [
  { id: "home", labelKey: "navHome", icon: Home },
  { id: "pomodoro", labelKey: "navPomodoro", icon: Timer },
  { id: "habits", labelKey: "navHabits", icon: Target },
  { id: "stats", labelKey: "navStats", icon: BarChart3 },
  { id: "settings", labelKey: "navSettings", icon: Settings },
];

export function getNavTabs(locale: LocaleId) {
  return TAB_DEFS.map(({ id, labelKey, icon }) => ({
    id,
    label: translate(locale, labelKey),
    icon,
  }));
}

/** @deprecated use getNavTabs(locale) */
export const NAV_TABS = getNavTabs("tr");
