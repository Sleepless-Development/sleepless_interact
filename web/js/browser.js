import { applyTheme, THEMES } from "./theme.js";
import { onSelect, resetHold, setCurrentIndex, updateHighlight } from "./controls.js";
import { isEnvBrowser } from "./env.js";
import { setMenuConfig, tryOpenMenu } from "./menu.js";

export { isEnvBrowser };

const MOCK_OPTIONS = {
  global: [
    { label: "Open trunk", icon: "fa-solid fa-car-rear" },
    { label: "Search", icon: "fa-solid fa-magnifying-glass" },
    { label: "Lockpick", icon: "fa-solid fa-unlock", holdTime: 1600 },
    { label: "Examine", icon: "fa-solid fa-eye" },
  ],
};

function optionsFromParams(params) {
  if (params.get("count") === "1") {
    return { global: [MOCK_OPTIONS.global[0]] };
  }
  return MOCK_OPTIONS;
}

function seedOptions(options = MOCK_OPTIONS) {
  window.postMessage({ action: "visible", value: true }, "*");
  window.postMessage(
    {
      action: "setOptions",
      value: {
        resetIndex: true,
        options,
      },
    },
    "*"
  );
}

function mountDock(params) {
  const dock = document.getElementById("browser-dock");
  const themes = document.getElementById("browser-themes");
  const cooldown = document.getElementById("browser-cooldown");
  const compact = document.getElementById("browser-compact");
  if (!dock || !themes) return;

  dock.hidden = false;

  THEMES.forEach((theme) => {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = theme.label;
    button.dataset.theme = theme.id;
    if (document.documentElement.dataset.theme === theme.id) {
      button.classList.add("is-active");
    }
    button.addEventListener("click", () => {
      applyTheme(theme.id);
      updateHighlight();
      themes.querySelectorAll("button").forEach((node) => {
        node.classList.toggle("is-active", node.dataset.theme === theme.id);
      });
    });
    themes.appendChild(button);
  });

  if (compact) {
    const compactOn = params.get("compact") !== "0";
    compact.classList.toggle("is-active", compactOn);
    compact.addEventListener("click", () => {
      const next = !compact.classList.contains("is-active");
      compact.classList.toggle("is-active", next);
      setMenuConfig({ compact: next });
      window.postMessage(
        {
          action: "setOptions",
          value: { resetIndex: true, options: MOCK_OPTIONS },
        },
        "*"
      );
    });
  }

  if (cooldown) {
    cooldown.addEventListener("click", () => {
      const next = !document.body.classList.contains("is-cooldown");
      window.postMessage({ action: "setCooldown", value: next }, "*");
      cooldown.classList.toggle("is-active", next);
    });
  }
}

export function setupBrowserMode() {
  if (!isEnvBrowser()) return;

  document.documentElement.dataset.browser = "true";

  const params = new URLSearchParams(window.location.search);
  const theme = params.get("theme") || document.documentElement.dataset.theme || "modern";
  applyTheme(theme);
  setMenuConfig({
    compact: params.get("compact") !== "0",
    idleMs: Number(params.get("idle")) || 2500,
  });
  mountDock(params);

  const applyPreviewState = () => {
    const optionIndex = Number(params.get("index") || 0);
    const state = params.get("state");

    if (state === "open" || state === "hold" || optionIndex > 0) {
      tryOpenMenu();
    }

    if (optionIndex > 0) {
      setCurrentIndex(optionIndex);
    }
    updateHighlight();

    if (state === "cooldown") {
      window.postMessage({ action: "setCooldown", value: true }, "*");
      const cooldown = document.getElementById("browser-cooldown");
      if (cooldown) cooldown.classList.add("is-active");
    }

    if (state === "hold") {
      const progress = document.getElementById("interact-progress");
      const interact = document.getElementById("interact-container");
      if (interact) interact.classList.add("is-holding");
      if (progress) progress.style.height = "62%";
    }
  };

  window.addEventListener("message", (event) => {
    if (event.data?.action === "setOptions") {
      requestAnimationFrame(applyPreviewState);
    }
  });

  seedOptions(optionsFromParams(params));

  window.addEventListener("keydown", (event) => {
    if (event.repeat) return;
    if (event.code === "KeyE" || event.code === "Space") {
      event.preventDefault();
      onSelect();
    }
  });

  window.addEventListener("keyup", (event) => {
    if (event.code === "KeyE" || event.code === "Space") {
      resetHold();
    }
  });

  const interact = document.getElementById("interact-container");
  if (interact) {
    interact.addEventListener("mousedown", (event) => {
      event.preventDefault();
      onSelect();
    });
    window.addEventListener("mouseup", () => {
      resetHold();
    });
  }
}
