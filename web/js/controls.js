import { fetchNui } from "./fetchNui.js";
import { bumpIdle, closeMenu, isMenuOpen, tryOpenMenu } from "./menu.js";

const optionsList = document.getElementById("options-list");
const optionsWrapper = document.getElementById("options-wrapper");
const progressElement = document.getElementById("interact-progress");
const interactButton = document.getElementById("interact-container");
const container = document.getElementById("container");

let currentIndex = 0;
let isHolding = false;
let holdTimeout = null;
let defaultColor = null;

function getOptions() {
  return optionsList.querySelectorAll(".option-container");
}

function srgbToLin(channel) {
  const c = channel / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

function onAccentFor(r, g, b) {
  const luminance =
    0.2126 * srgbToLin(r) + 0.7152 * srgbToLin(g) + 0.0722 * srgbToLin(b);
  return luminance > 0.28 ? "8, 11, 16" : "236, 241, 247";
}

function clearAccent() {
  document.body.style.removeProperty("--theme-color");
  document.body.style.removeProperty("--primary");
  document.body.style.removeProperty("--on-accent");
}

function applyAccent(color) {
  if (!color) {
    clearAccent();
    return;
  }
  document.body.style.setProperty("--theme-color", color);

  const match = String(color).match(/(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
  if (match) {
    const r = Number(match[1]);
    const g = Number(match[2]);
    const b = Number(match[3]);
    document.body.style.setProperty("--primary", `${r}, ${g}, ${b}`);
    document.body.style.setProperty("--on-accent", onAccentFor(r, g, b));
  }
}

export function restoreDefaultAccent() {
  if (defaultColor) applyAccent(defaultColor);
  else clearAccent();
}

export function checkHideButton() {
  if (!isMenuOpen()) {
    interactButton.style.visibility = "visible";
    return;
  }

  const option = getOptions()[currentIndex];
  interactButton.style.visibility = option && option.hideButton ? "hidden" : "visible";
}

export function setDefaultColor(color) {
  defaultColor = color;
  applyAccent(color);
  return defaultColor;
}

export function setCurrentIndex(newIndex) {
  currentIndex = newIndex;
  checkHideButton();
  return currentIndex;
}

function collapseAfterSelect() {
  if (!closeMenu()) return;
  setCurrentIndex(0);
  updateHighlight();
}

export function onSelect() {
  if (tryOpenMenu()) {
    requestAnimationFrame(() => updateHighlight());
    return;
  }

  const option = getOptions()[currentIndex];
  if (!option) return;

  if (option.holdTime) {
    startHold(option);
    fetchNui("startHoldAnim", [option.targetType, option.targetId]);
    return;
  }

  fetchNui("select", [option.targetType, option.targetId]);
  collapseAfterSelect();
}

function completeHold(option) {
  if (!isHolding) return;

  const currentOption = getOptions()[currentIndex];
  if (!currentOption || currentOption !== option) return;

  fetchNui("select", [option.targetType, option.targetId]);
  collapseAfterSelect();
}

export function resetHold() {
  if (!isHolding) return;

  isHolding = false;
  clearTimeout(holdTimeout);
  progressElement.style.transition = "none";
  progressElement.style.height = "0";
  interactButton.classList.remove("is-holding");
  bumpIdle();

  fetchNui("endHoldAnim");
}

function startHold(option) {
  if (isHolding) return;

  isHolding = true;
  interactButton.classList.add("is-holding");
  progressElement.style.transition = `height ${option.holdTime}ms linear`;
  progressElement.style.height = "100%";

  holdTimeout = setTimeout(() => {
    completeHold(option);
  }, option.holdTime);
}

function syncSelectedAlignment() {
  optionsWrapper.style.removeProperty("translate");
}

export function updateHighlight() {
  const options = getOptions();
  if (options.length > 0) {
    options.forEach((option) => option.classList.remove("highlighted"));
    const active = options[currentIndex] || options[0];
    if (active) active.classList.add("highlighted");

    if (active?.color) {
      const c = active.color;
      applyAccent(`rgb(${c[0]}, ${c[1]}, ${c[2]}, ${c[3] / 255})`);
    } else {
      restoreDefaultAccent();
    }
  }

  syncSelectedAlignment();
}

window.addEventListener("wheel", (event) => {
  if (isHolding) return;
  if (!isMenuOpen()) return;

  const options = getOptions();
  if (options.length === 0) return;

  if (event.deltaY > 0) {
    currentIndex = setCurrentIndex((currentIndex + 1) % options.length);
  } else {
    currentIndex = setCurrentIndex((currentIndex - 1 + options.length) % options.length);
  }

  updateHighlight();
  bumpIdle();
  fetchNui("currentOption", [currentIndex + 1]);
});

container.addEventListener("menu-collapsed", () => {
  setCurrentIndex(0);
  updateHighlight();
});

updateHighlight();
