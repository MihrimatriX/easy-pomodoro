"use client";

import { useRef } from "react";
import { Download, HardDrive, Languages, Palette, Upload, Volume2 } from "lucide-react";
import { LOCALES, themeLabel } from "@shared/i18n/messages";
import { COLOR_THEMES } from "@shared/themes";
import type {
  ColorThemeId,
  LocaleId,
  Settings as AppSettings,
  ThemeMode,
} from "@shared/types";
import { playCompletionSound } from "@/lib/sounds";
import { requestNotificationPermission } from "@/lib/notifications";
import {
  clearAllData,
  exportBackup,
  importBackup,
} from "@/lib/storage";
import { getTodayKey } from "@shared/pomodoro";
import { NeoStepper } from "@/components/NeoStepper";
import { NeoSelect } from "@/components/NeoSelect";
import { UiStylePicker } from "@/components/UiStylePicker";
import { useLocale, useT } from "@/context/LocaleContext";

type SettingsPanelProps = {
  settings: AppSettings;
  onChange: (patch: Partial<AppSettings>) => void;
};

function NumberField({
  label,
  value,
  onChange,
  min = 1,
  max = 120,
}: {
  label: string;
  value: number;
  onChange: (v: number) => void;
  min?: number;
  max?: number;
}) {
  return (
    <div className="flex items-center justify-between gap-4 py-2.5">
      <span className="text-base text-foreground/85">{label}</span>
      <NeoStepper
        value={value}
        onChange={onChange}
        min={min}
        max={max}
        ariaLabel={label}
      />
    </div>
  );
}

function Toggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="flex items-center justify-between gap-4 py-2.5">
      <span className="text-base text-foreground/85">{label}</span>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative h-7 w-12 rounded-full transition cursor-pointer ${
          checked ? "neo-btn-primary !rounded-full !p-0" : "neo-inset-sm"
        }`}
      >
        <span
          className={`absolute top-0.5 left-0.5 h-6 w-6 rounded-full bg-[var(--knob)] shadow-sm transition ${
            checked ? "translate-x-5" : ""
          }`}
        />
      </button>
    </label>
  );
}

export function SettingsPanel({ settings, onChange }: SettingsPanelProps) {
  const t = useT();
  const locale = useLocale();
  const fileRef = useRef<HTMLInputElement>(null);

  const selectTheme = (id: ColorThemeId) => onChange({ colorTheme: id });
  const selectLocale = (id: LocaleId) => onChange({ locale: id });

  const handleExport = () => {
    const blob = new Blob([JSON.stringify(exportBackup(), null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `neo-pomodoro-${getTodayKey()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleImportFile = async (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    try {
      const parsed: unknown = JSON.parse(await file.text());
      if (!importBackup(parsed)) {
        window.alert(t("importError"));
        return;
      }
      window.location.reload();
    } catch {
      window.alert(t("importError"));
    }
  };

  const handleReset = () => {
    if (!window.confirm(t("confirmReset"))) return;
    clearAllData();
    window.location.reload();
  };

  return (
    <div className="flex w-full max-w-lg flex-col gap-6 content-panel">
      <section className="neo-surface p-5">
        <h2 className="mb-4 flex items-center gap-2 text-base font-semibold text-foreground">
          <Languages size={18} className="text-accent" />
          {t("settingsLanguage")}
        </h2>
        <div className="language-row">
          {LOCALES.map((loc) => (
            <button
              key={loc.id}
              type="button"
              onClick={() => selectLocale(loc.id)}
              className={`language-btn neo-surface-sm ${settings.locale === loc.id ? "active" : ""}`}
              aria-pressed={settings.locale === loc.id}
            >
              <span aria-hidden>{loc.flag}</span>
              {loc.label}
            </button>
          ))}
        </div>
      </section>

      <section className="neo-surface p-5">
        <h2 className="mb-4 flex items-center gap-2 text-base font-semibold text-foreground">
          <Palette size={18} className="text-accent" />
          {t("settingsAppearance")}
        </h2>

        <p className="section-label mb-3">{t("uiStyle")}</p>
        <p className="mb-3 text-sm font-medium text-muted">
          {t("uiStyleHint")}
        </p>
        <UiStylePicker
          locale={locale}
          value={settings.uiStyle}
          onChange={(uiStyle) => onChange({ uiStyle })}
        />

        <p className="section-label mb-3 mt-5">{t("themeMode")}</p>
        <div className="theme-mode-row">
          {(
            [
              { id: "light", label: t("themeLight") },
              { id: "dark", label: t("themeDark") },
              { id: "system", label: t("themeSystem") },
            ] as { id: ThemeMode; label: string }[]
          ).map((m) => (
            <button
              key={m.id}
              type="button"
              onClick={() => onChange({ theme: m.id })}
              className={`theme-mode-btn neo-surface-sm ${settings.theme === m.id ? "active" : ""}`}
              aria-pressed={settings.theme === m.id}
            >
              {m.label}
            </button>
          ))}
        </div>

        <p className="section-label mb-3 mt-5">{t("colorPalette")}</p>
        <div className="theme-swatch-grid">
          {COLOR_THEMES.map((theme) => (
            <button
              key={theme.id}
              type="button"
              onClick={() => selectTheme(theme.id)}
              className={`theme-swatch ${settings.colorTheme === theme.id ? "active" : ""}`}
              aria-pressed={settings.colorTheme === theme.id}
            >
              <span
                className="theme-swatch-dot"
                style={{ background: theme.swatch }}
                aria-hidden
              />
              <span className="theme-swatch-label">
                {themeLabel(locale, theme.id)}
              </span>
            </button>
          ))}
          <button
            type="button"
            onClick={() => selectTheme("custom")}
            className={`theme-swatch ${settings.colorTheme === "custom" ? "active" : ""}`}
            aria-pressed={settings.colorTheme === "custom"}
          >
            <span
              className="theme-swatch-dot"
              style={{
                background: `conic-gradient(from 120deg, ${settings.customAccent}, #14b8a6, #6366f1, ${settings.customAccent})`,
              }}
              aria-hidden
            />
            <span className="theme-swatch-label">{t("custom")}</span>
          </button>
        </div>

        {settings.colorTheme === "custom" && (
          <div className="theme-custom-row">
            <input
              type="color"
              value={settings.customAccent}
              onChange={(e) => onChange({ customAccent: e.target.value })}
              aria-label={t("customAccent")}
            />
            <span className="text-sm font-medium text-muted">
              {t("customAccent")}
            </span>
          </div>
        )}
      </section>

      <section className="neo-surface p-5">
        <h2 className="mb-3 text-base font-semibold text-foreground">
          {t("durations")}
        </h2>
        <NumberField
          label={t("focusDuration")}
          value={settings.focusMin}
          onChange={(v) => onChange({ focusMin: v })}
        />
        <NumberField
          label={t("shortBreak")}
          value={settings.shortBreakMin}
          onChange={(v) => onChange({ shortBreakMin: v })}
        />
        <NumberField
          label={t("longBreak")}
          value={settings.longBreakMin}
          onChange={(v) => onChange({ longBreakMin: v })}
        />
        <NumberField
          label={t("longBreakInterval")}
          value={settings.longBreakInterval}
          onChange={(v) => onChange({ longBreakInterval: v })}
          max={20}
        />
      </section>

      <section className="neo-surface p-5">
        <h2 className="mb-3 text-base font-semibold text-foreground">
          {t("preferences")}
        </h2>
        <Toggle
          label={t("autoStart")}
          checked={settings.autoStart}
          onChange={(v) => onChange({ autoStart: v })}
        />
        <Toggle
          label={t("sound")}
          checked={settings.sound}
          onChange={(v) => onChange({ sound: v })}
        />

        {settings.sound && (
          <div className="mt-1 flex items-center justify-between gap-4 border-t border-[var(--hairline)] py-2 pt-3">
            <span className="pl-2 text-base text-foreground/85">
              {t("soundType")}
            </span>
            <div className="flex items-center gap-2">
              <NeoSelect
                value={settings.soundType || "chime"}
                onChange={(val) =>
                  onChange({
                    soundType: val as "chime" | "digital" | "bird" | "gong",
                  })
                }
                ariaLabel={t("soundType")}
              >
                <option value="chime">{t("soundChime")}</option>
                <option value="digital">{t("soundDigital")}</option>
                <option value="bird">{t("soundBird")}</option>
                <option value="gong">{t("soundGong")}</option>
              </NeoSelect>
              <button
                type="button"
                onClick={() =>
                  playCompletionSound(settings.soundType || "chime")
                }
                className="neo-icon-btn flex h-10 w-10 shrink-0 items-center justify-center text-muted"
                aria-label={t("soundType")}
              >
                <Volume2 size={16} />
              </button>
            </div>
          </div>
        )}

        <Toggle
          label={t("notifications")}
          checked={settings.notifications}
          onChange={(v) => {
            void (async () => {
              if (v) {
                const ok = await requestNotificationPermission();
                onChange({ notifications: ok });
                return;
              }
              onChange({ notifications: false });
            })();
          }}
        />
      </section>

      <section className="neo-surface p-5">
        <h2 className="mb-3 flex items-center gap-2 text-base font-semibold text-foreground">
          <HardDrive size={18} className="text-accent" />
          {t("dataSection")}
        </h2>
        <p className="mb-4 text-sm font-medium text-muted">{t("exportHint")}</p>
        <input
          ref={fileRef}
          type="file"
          accept="application/json,.json"
          className="hidden"
          onChange={handleImportFile}
        />
        <div className="flex flex-col gap-2 sm:flex-row">
          <button
            type="button"
            onClick={handleExport}
            className="neo-btn flex flex-1 items-center justify-center gap-2 py-2.5 text-base font-medium text-foreground"
          >
            <Download size={16} />
            {t("exportData")}
          </button>
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="neo-btn flex flex-1 items-center justify-center gap-2 py-2.5 text-base font-medium text-foreground"
          >
            <Upload size={16} />
            {t("importData")}
          </button>
        </div>
        <button
          type="button"
          onClick={handleReset}
          className="mt-3 w-full py-2 text-sm font-medium text-muted underline-offset-2 hover:text-accent hover:underline"
        >
          {t("resetData")}
        </button>
      </section>

      <section className="neo-surface-sm p-5">
        <div className="storage-info">
          <HardDrive size={20} className="mt-0.5 shrink-0 text-accent" />
          <p>
            <strong>{t("localStorageTitle")}</strong> {t("localStorageBody")}
          </p>
        </div>
      </section>
    </div>
  );
}
