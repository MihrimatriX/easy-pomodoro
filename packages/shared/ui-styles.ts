import type { UiStyleId } from "./types";

export type UiStyleMeta = {
  id: UiStyleId;
  icon: string;
  previewClass: string;
};

export const UI_STYLES: UiStyleMeta[] = [
  { id: "neo", icon: "◐", previewClass: "ui-preview-neo" },
  { id: "clay", icon: "●", previewClass: "ui-preview-clay" },
  { id: "skeuo", icon: "▣", previewClass: "ui-preview-skeuo" },
  { id: "flat", icon: "▢", previewClass: "ui-preview-flat" },
  { id: "glass", icon: "◇", previewClass: "ui-preview-glass" },
  { id: "liquid", icon: "◈", previewClass: "ui-preview-liquid" },
];

export function normalizeUiStyle(
  value: unknown,
  legacyBlend?: number,
): UiStyleId {
  const valid: UiStyleId[] = [
    "neo",
    "glass",
    "clay",
    "skeuo",
    "liquid",
    "flat",
  ];
  if (typeof value === "string" && valid.includes(value as UiStyleId)) {
    return value as UiStyleId;
  }
  if (typeof legacyBlend === "number") {
    if (legacyBlend <= 15) return "neo";
    if (legacyBlend <= 35) return "clay";
    if (legacyBlend <= 60) return "glass";
    if (legacyBlend <= 80) return "skeuo";
    return "liquid";
  }
  return "neo";
}
