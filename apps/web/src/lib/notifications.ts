import { getPhaseMessage } from "@shared/i18n/messages";
import type { LocaleId, Phase } from "@shared/types";

export async function requestNotificationPermission(): Promise<boolean> {
  if (typeof window === "undefined" || !("Notification" in window)) {
    return false;
  }
  if (Notification.permission === "granted") return true;
  if (Notification.permission === "denied") return false;
  const result = await Notification.requestPermission();
  return result === "granted";
}

export function showPhaseNotification(phase: Phase, locale: LocaleId): void {
  if (typeof window === "undefined" || !("Notification" in window)) return;
  if (Notification.permission !== "granted") return;
  const { title, body } = getPhaseMessage(locale, phase);
  new Notification(title, { body, icon: "/icons/icon.svg" });
}
