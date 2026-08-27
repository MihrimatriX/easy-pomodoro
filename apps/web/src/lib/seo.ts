import { APP_DESCRIPTION, APP_NAME, APP_TAGLINE } from "@shared/app-copy";

export function getSiteUrl(): string {
  const raw = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  return raw.replace(/\/$/, "");
}

export const SEO = {
  name: APP_NAME,
  shortName: "Pomodoro",
  tagline: APP_TAGLINE,
  description: APP_DESCRIPTION,
  title: `${APP_NAME} — ${APP_TAGLINE}`,
  locale: "tr_TR",
  keywords: [
    "pomodoro",
    "pomodoro timer",
    "pomodoro tekniği",
    "focus timer",
    "zamanlayıcı",
    "odaklanma",
    "üretkenlik",
    "productivity app",
    "habit tracker",
    "alışkanlık takibi",
    "görev yönetimi",
    "task list",
    "PWA",
    "offline pomodoro",
  ],
} as const;
