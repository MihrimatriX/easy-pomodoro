/**
 * Server-safe part of the theme system (imported by the root layout).
 * See lib/theme.ts for how the cache is written.
 */

export const THEME_CACHE_KEY = "easy-pomodoro:theme-cache";

/**
 * Inline <head> script: re-applies the cached theme before first paint.
 * Kept dependency-free and tiny; mirrors applyResolvedTheme().
 */
export const THEME_BOOT_SCRIPT = `(function(){try{var c=JSON.parse(localStorage.getItem(${JSON.stringify(
  THEME_CACHE_KEY,
)})||"null");if(!c)return;var m=c.pref==="system"?(matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"):c.pref;var t=c[m]||c.light||c.dark;if(!t)return;var r=document.documentElement;for(var k in t.vars)r.style.setProperty(k,t.vars[k]);r.style.colorScheme=t.mode;r.dataset.colorTheme=t.colorTheme;r.dataset.uiStyle=t.uiStyle;r.dataset.theme=t.mode;r.lang=t.lang;}catch(e){}})();`;
