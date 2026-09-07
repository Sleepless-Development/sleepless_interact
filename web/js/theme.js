const FALLBACK_THEME = "modern";

export const THEMES = [
  { id: "legacy", label: "Legacy" },
  { id: "modern", label: "Modern" },
  { id: "minimal", label: "Minimal" },
  { id: "light", label: "Light" },
  { id: "retro", label: "Retro" },
  { id: "cyber", label: "Cyber" },
  { id: "vice", label: "Vice" },
  { id: "noir", label: "Noir" },
  { id: "industrial", label: "Industrial" },
  { id: "fantasy", label: "Fantasy" },
];

const loadedThemes = new Set(THEMES.map((theme) => theme.id));

export function applyTheme(name) {
  const theme = String(name || FALLBACK_THEME)
    .toLowerCase()
    .trim() || FALLBACK_THEME;

  if (!loadedThemes.has(theme)) {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = `themes/${theme}.css`;
    link.addEventListener("error", () => {
      loadedThemes.delete(theme);
      if (theme !== FALLBACK_THEME) applyTheme(FALLBACK_THEME);
    });
    document.head.appendChild(link);
    loadedThemes.add(theme);
  }

  document.documentElement.dataset.theme = theme;
  return theme;
}

applyTheme(document.documentElement.dataset.theme || FALLBACK_THEME);
