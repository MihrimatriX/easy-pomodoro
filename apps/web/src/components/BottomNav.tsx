"use client";

import { getNavTabs, type TabId } from "@/components/nav-tabs";

import { useLocale, useT } from "@/context/LocaleContext";

export type { TabId };

type BottomNavProps = {
  active: TabId;

  onChange: (tab: TabId) => void;
};

export function BottomNav({ active, onChange }: BottomNavProps) {
  const locale = useLocale();
  const t = useT();
  const tabs = getNavTabs(locale);

  return (
    <nav
      className="neo-nav mobile-bottom-nav fixed bottom-0 z-50 pb-[env(safe-area-inset-bottom)]"
      aria-label={t("mainNav")}
    >
      <div className="flex h-full w-full items-center justify-around px-1 pt-2.5">
        {tabs.map(({ id, label, shortLabel, icon: Icon }) => (
          <button
            key={id}
            type="button"
            onClick={() => onChange(id)}
            aria-current={active === id ? "page" : undefined}
            aria-label={label}
            title={label}
            className={`nav-item ${active === id ? "active" : ""}`}
          >
            <Icon size={22} aria-hidden />
            <span className="nav-item-label">{shortLabel}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}
