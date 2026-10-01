"use client";

import { UI_STYLES } from "@shared/ui-styles";
import { uiStyleDesc, uiStyleLabel } from "@shared/i18n/messages";
import type { LocaleId, UiStyleId } from "@shared/types";

type UiStylePickerProps = {
  locale: LocaleId;
  value: UiStyleId;
  onChange: (style: UiStyleId, event: React.MouseEvent<HTMLButtonElement>) => void;
};

export function UiStylePicker({ locale, value, onChange }: UiStylePickerProps) {
  return (
    <div className="ui-style-grid">
      {UI_STYLES.map((style) => (
        <button
          key={style.id}
          type="button"
          onClick={(event) => onChange(style.id, event)}
          className={`ui-style-card ${value === style.id ? "active" : ""}`}
          aria-pressed={value === style.id}
        >
          <div
            className={`ui-style-preview ${style.previewClass}`}
            aria-hidden
          />
          <span className="ui-style-card-label">
            {uiStyleLabel(locale, style.id)}
          </span>
          <span className="ui-style-card-desc">
            {uiStyleDesc(locale, style.id)}
          </span>
        </button>
      ))}
    </div>
  );
}
