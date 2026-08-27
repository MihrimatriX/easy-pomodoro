"use client";

import { createContext, useCallback, useContext } from "react";
import { translate, type MessageKey } from "@shared/i18n/messages";
import type { LocaleId } from "@shared/types";

const LocaleContext = createContext<LocaleId>("tr");

export function LocaleProvider({
  locale,
  children,
}: {
  locale: LocaleId;
  children: React.ReactNode;
}) {
  return (
    <LocaleContext.Provider value={locale}>{children}</LocaleContext.Provider>
  );
}

export function useLocale(): LocaleId {
  return useContext(LocaleContext);
}

export function useT() {
  const locale = useLocale();
  return useCallback(
    (key: MessageKey, params?: Record<string, string | number>) =>
      translate(locale, key, params),
    [locale],
  );
}
