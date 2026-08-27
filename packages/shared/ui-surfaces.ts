import type { UiStyleId } from "./types";

export type UiMode = "light" | "dark";

/**
 * Bir UI stilinin (neo/clay/skeuo/flat/glass/liquid) belirli bir modda (light/dark)
 * ve verilen vurgu renginde ürettiği tam yüzey paleti. Hem web (CSS değişkenleri)
 * Web (CSS) tarafından tek kaynak olarak kullanılır.
 */
export type UiSurface = {
  mode: UiMode;
  /** Sayfa arka planı (düz) */
  background: string;
  /** Arka plan gradyanı (web body) */
  gradient: [string, string, string];
  /** Kart / panel yüzeyi (opak) */
  surface: string;
  /** Cam stillerinde yarı saydam yüzey (rgba) */
  surfaceTranslucent: string;
  /** Input / inset yüzeyi */
  inputBg: string;
  foreground: string;
  muted: string;
  border: string;
  /** Neumorphism açık gölge (sol-üst) */
  shadowLight: string;
  /** Neumorphism koyu gölge (sağ-alt) */
  shadowDark: string;
  glassBg: string;
  glassBorder: string;
  traits: UiTraits;
};

export type UiTraits = {
  radiusLg: number;
  radiusMd: number;
  radiusSm: number;
  /** Yüzey kenarlık kalınlığı (px) */
  borderWidth: number;
  /** RN raised gölge ayarları */
  shadowOpacity: number;
  shadowRadius: number;
  shadowOffsetY: number;
  elevation: number;
  /** Gölgesiz düz tasarım */
  flat: boolean;
  /** Cam (blur/translucency) tabanlı */
  translucent: boolean;
  /** Web blur miktarı (px) */
  blur: number;
};

// ── renk yardımcıları ──
function parseHex(hex: string): { r: number; g: number; b: number } {
  let h = hex.replace("#", "").trim();
  if (h.length === 3) {
    h = h
      .split("")
      .map((c) => c + c)
      .join("");
  }
  const n = parseInt(h, 16);
  if (Number.isNaN(n) || h.length !== 6) return { r: 99, g: 102, b: 241 };
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

function clamp(n: number): number {
  return Math.max(0, Math.min(255, Math.round(n)));
}

function toHex({ r, g, b }: { r: number; g: number; b: number }): string {
  const h = (v: number) => clamp(v).toString(16).padStart(2, "0");
  return `#${h(r)}${h(g)}${h(b)}`;
}

/** t = c1'in ağırlığı (0..1) */
export function mix(c1: string, c2: string, t: number): string {
  const a = parseHex(c1);
  const b = parseHex(c2);
  return toHex({
    r: a.r * t + b.r * (1 - t),
    g: a.g * t + b.g * (1 - t),
    b: a.b * t + b.b * (1 - t),
  });
}

export function withAlpha(hex: string, alpha: number): string {
  const { r, g, b } = parseHex(hex);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

const TRAITS: Record<UiStyleId, UiTraits> = {
  neo: {
    radiusLg: 22,
    radiusMd: 16,
    radiusSm: 12,
    borderWidth: 0,
    shadowOpacity: 0.4,
    shadowRadius: 12,
    shadowOffsetY: 6,
    elevation: 6,
    flat: false,
    translucent: false,
    blur: 0,
  },
  clay: {
    radiusLg: 30,
    radiusMd: 22,
    radiusSm: 16,
    borderWidth: 0,
    shadowOpacity: 0.3,
    shadowRadius: 6,
    shadowOffsetY: 10,
    elevation: 8,
    flat: false,
    translucent: false,
    blur: 0,
  },
  skeuo: {
    radiusLg: 12,
    radiusMd: 9,
    radiusSm: 6,
    borderWidth: 1,
    shadowOpacity: 0.42,
    shadowRadius: 6,
    shadowOffsetY: 4,
    elevation: 5,
    flat: false,
    translucent: false,
    blur: 0,
  },
  flat: {
    radiusLg: 16,
    radiusMd: 12,
    radiusSm: 8,
    borderWidth: 1,
    shadowOpacity: 0,
    shadowRadius: 0,
    shadowOffsetY: 0,
    elevation: 0,
    flat: true,
    translucent: false,
    blur: 0,
  },
  glass: {
    radiusLg: 24,
    radiusMd: 18,
    radiusSm: 14,
    borderWidth: 1,
    shadowOpacity: 0.16,
    shadowRadius: 18,
    shadowOffsetY: 10,
    elevation: 3,
    flat: false,
    translucent: true,
    blur: 22,
  },
  liquid: {
    radiusLg: 32,
    radiusMd: 26,
    radiusSm: 20,
    borderWidth: 1,
    shadowOpacity: 0.2,
    shadowRadius: 26,
    shadowOffsetY: 14,
    elevation: 4,
    flat: false,
    translucent: true,
    blur: 40,
  },
};

/**
 * Stile + moda + vurgu rengine göre tam yüzey paletini döndürür.
 */
export function getUiSurface(
  uiStyle: UiStyleId,
  mode: UiMode,
  accent: string,
): UiSurface {
  const traits = TRAITS[uiStyle];
  const dark = mode === "dark";

  switch (uiStyle) {
    case "neo": {
      if (dark) {
        return {
          mode,
          background: "#262d3b",
          gradient: ["#242b39", "#1f2531", "#1a1f2a"],
          surface: "#262d3b",
          surfaceTranslucent: "#262d3b",
          inputBg: "#222936",
          foreground: "#eaf0f9",
          muted: "#b7c3d8",
          border: "rgba(255,255,255,0.05)",
          shadowLight: "#323c4f",
          shadowDark: "#141923",
          glassBg: "rgba(40,48,64,0.6)",
          glassBorder: "rgba(255,255,255,0.06)",
          traits,
        };
      }
      return {
        mode,
        background: "#e8eef8",
        gradient: ["#eef3fb", "#e0e9f8", "#dce6f7"],
        surface: "#e8eef8",
        surfaceTranslucent: "#e8eef8",
        inputBg: "#e8eef8",
        foreground: "#152a45",
        muted: "#4a5c72",
        border: "#c5d0e4",
        shadowLight: "#f5f8fc",
        shadowDark: "#b8c4d8",
        glassBg: "rgba(255,255,255,0.42)",
        glassBorder: "rgba(255,255,255,0.55)",
        traits,
      };
    }

    case "skeuo": {
      if (dark) {
        return {
          mode,
          background: "#26292e",
          gradient: ["#303338", "#292c30", "#222427"],
          surface: "#3a3e44",
          surfaceTranslucent: "#3a3e44",
          inputBg: "#2c2f34",
          foreground: "#e8eaed",
          muted: "#a3a8b0",
          border: "#54585f",
          shadowLight: "#5c636e",
          shadowDark: "#101113",
          glassBg: "rgba(58,62,68,0.6)",
          glassBorder: "rgba(255,255,255,0.08)",
          traits,
        };
      }
      return {
        mode,
        background: "#b6b9be",
        gradient: ["#c1c4c9", "#b5b8be", "#a9adb4"],
        surface: "#d7dade",
        surfaceTranslucent: "#d7dade",
        inputBg: "#c8ccd1",
        foreground: "#272c34",
        muted: "#565d68",
        border: "#9298a1",
        shadowLight: "#ffffff",
        shadowDark: "#7e848c",
        glassBg: "rgba(255,255,255,0.4)",
        glassBorder: "rgba(255,255,255,0.55)",
        traits,
      };
    }

    case "clay": {
      if (dark) {
        const base = "#1c1a2b";
        return {
          mode,
          background: mix(accent, base, 0.18),
          gradient: [
            mix(accent, "#211e34", 0.16),
            mix(accent, "#1c1a2b", 0.18),
            mix(accent, "#181626", 0.2),
          ],
          surface: mix(accent, "#2a2740", 0.26),
          surfaceTranslucent: mix(accent, "#2a2740", 0.26),
          inputBg: mix(accent, "#232036", 0.2),
          foreground: "#f3f1fc",
          muted: mix("#ffffff", accent, 0.7),
          border: "transparent",
          shadowLight: mix(accent, "#3a3552", 0.32),
          shadowDark: mix(accent, "#0c0a16", 0.4),
          glassBg: mix(accent, "#2a2740", 0.3),
          glassBorder: "rgba(255,255,255,0.08)",
          traits,
        };
      }
      return {
        mode,
        background: mix(accent, "#eef0fb", 0.15),
        gradient: [
          mix(accent, "#f1f2fc", 0.12),
          mix(accent, "#eaecfa", 0.16),
          mix(accent, "#e3e6f8", 0.2),
        ],
        surface: mix(accent, "#ffffff", 0.06),
        surfaceTranslucent: mix(accent, "#ffffff", 0.06),
        inputBg: mix(accent, "#ffffff", 0.1),
        foreground: mix(accent, "#241f3a", 0.5),
        muted: mix(accent, "#6b6880", 0.3),
        border: "transparent",
        shadowLight: "#ffffff",
        shadowDark: mix(accent, "#b4b7d4", 0.38),
        glassBg: mix(accent, "#ffffff", 0.2),
        glassBorder: "rgba(255,255,255,0.6)",
        traits,
      };
    }

    case "flat": {
      if (dark) {
        return {
          mode,
          background: "#15181e",
          gradient: ["#181b22", "#15181e", "#121419"],
          surface: "#1e222b",
          surfaceTranslucent: "#1e222b",
          inputBg: "#1a1d25",
          foreground: "#eef1f6",
          muted: "#99a2b0",
          border: "#2c313c",
          shadowLight: "#2a2f3a",
          shadowDark: "#0c0e12",
          glassBg: "rgba(30,34,43,0.7)",
          glassBorder: "#2c313c",
          traits,
        };
      }
      return {
        mode,
        background: "#f3f5f9",
        gradient: ["#f5f7fb", "#f1f4f9", "#eef2f8"],
        surface: "#ffffff",
        surfaceTranslucent: "#ffffff",
        inputBg: "#ffffff",
        foreground: "#1b212d",
        muted: "#5b6675",
        border: "#e3e8f0",
        shadowLight: "#ffffff",
        shadowDark: "#dfe4ec",
        glassBg: "rgba(255,255,255,0.8)",
        glassBorder: "#e3e8f0",
        traits,
      };
    }

    case "glass": {
      if (dark) {
        return {
          mode,
          background: "#10141f",
          gradient: ["#141a28", "#10141f", "#0c1019"],
          surface: "rgba(40,52,74,0.55)",
          surfaceTranslucent: "rgba(255,255,255,0.08)",
          inputBg: "rgba(255,255,255,0.06)",
          foreground: "#eef2fb",
          muted: "#c0cbe4",
          border: "rgba(255,255,255,0.16)",
          shadowLight: "rgba(255,255,255,0.12)",
          shadowDark: "rgba(0,0,0,0.5)",
          glassBg: "rgba(255,255,255,0.11)",
          glassBorder: "rgba(255,255,255,0.16)",
          traits,
        };
      }
      return {
        mode,
        background: "#dce6f7",
        gradient: ["#eef3fb", "#e0e9f8", "#dce6f7"],
        surface: "rgba(255,255,255,0.55)",
        surfaceTranslucent: "rgba(255,255,255,0.22)",
        inputBg: "rgba(255,255,255,0.35)",
        foreground: "#152033",
        muted: "#3a4a63",
        border: "rgba(255,255,255,0.6)",
        shadowLight: "rgba(255,255,255,0.7)",
        shadowDark: "rgba(15,23,42,0.14)",
        glassBg: "rgba(255,255,255,0.22)",
        glassBorder: "rgba(255,255,255,0.6)",
        traits,
      };
    }

    case "liquid": {
      if (dark) {
        return {
          mode,
          background: "#0a1628",
          gradient: ["#0e1c33", "#0a1628", "#081120"],
          surface: "rgba(255,255,255,0.1)",
          surfaceTranslucent: "rgba(255,255,255,0.1)",
          inputBg: "rgba(255,255,255,0.08)",
          foreground: "#eef2ff",
          muted: "#c0cbe4",
          border: "rgba(255,255,255,0.22)",
          shadowLight: "rgba(255,255,255,0.18)",
          shadowDark: "rgba(0,0,0,0.55)",
          glassBg: "rgba(255,255,255,0.1)",
          glassBorder: "rgba(255,255,255,0.22)",
          traits,
        };
      }
      return {
        mode,
        background: mix(accent, "#e6eefb", 0.12),
        gradient: [
          mix(accent, "#eef3fb", 0.1),
          mix(accent, "#dde8f8", 0.16),
          mix(accent, "#d2e0f6", 0.2),
        ],
        surface: "rgba(255,255,255,0.45)",
        surfaceTranslucent: "rgba(255,255,255,0.28)",
        inputBg: "rgba(255,255,255,0.4)",
        foreground: "#11203a",
        muted: "#3a4a63",
        border: "rgba(255,255,255,0.65)",
        shadowLight: "rgba(255,255,255,0.8)",
        shadowDark: "rgba(15,23,42,0.16)",
        glassBg: "rgba(255,255,255,0.28)",
        glassBorder: "rgba(255,255,255,0.65)",
        traits,
      };
    }

    default:
      return getUiSurface("neo", mode, accent);
  }
}

/** system → light/dark çözümü için yardımcı (platforma göre prefersDark verilir) */
export function resolveMode(
  themeMode: "system" | "light" | "dark",
  prefersDark: boolean,
): UiMode {
  if (themeMode === "system") return prefersDark ? "dark" : "light";
  return themeMode;
}
