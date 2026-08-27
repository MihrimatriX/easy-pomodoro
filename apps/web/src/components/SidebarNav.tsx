"use client";

import { getNavTabs, type TabId } from "@/components/nav-tabs";
import { useLocale, useT } from "@/context/LocaleContext";

type SidebarNavProps = {
  active: TabId;
  onChange: (tab: TabId) => void;
};

export function SidebarNav({ active, onChange }: SidebarNavProps) {
  const locale = useLocale();
  const t = useT();
  const tabs = getNavTabs(locale);

  return (
    <aside className="desktop-sidebar" aria-label={t("mainNav")}>
      <p className="logo text-foreground">{t("appName")}</p>
      <nav className="sidebar-nav">
        {tabs.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            type="button"
            onClick={() => onChange(id)}
            aria-current={active === id ? "page" : undefined}
            className={`sidebar-link ${active === id ? "active" : ""}`}
          >
            <Icon size={22} strokeWidth={2} />
            <span className="sidebar-link-label">{label}</span>
          </button>
        ))}
      </nav>
    </aside>
  );
}
