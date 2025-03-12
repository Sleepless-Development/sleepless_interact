import { fetchNui } from "./fetchNui.js";
const optionsWrapper = document.getElementById("options-wrapper");
const progressElement = document.getElementById("interact-progress");

let currentIndex = 0;
let isHolding = false;
let holdStartTime = null;
let holdTimeout = null;
let defaultColor = null;

export function setDefaultColor(color) {
  defaultColor = color;
  return defaultColor;
}

export function setCurrentIndex(newIndex) {
  currentIndex = newIndex;
  return currentIndex;
}

export function onSelect() {
  const options = optionsWrapper.querySelectorAll(".option-container");
  const option = options[currentIndex];

  if (!option) return;
  
  if (option.holdTime) {
    startHold(option);
  } else {
    fetchNui("select", [option.targetType, option.targetId]);
  }
}

function completeHold(option) {
  if (!isHolding) return;
  
  const options = optionsWrapper.querySelectorAll(".option-container");
  const currentOption = options[currentIndex];

  if (!currentOption) return;
  
  // Verify it's still the same option
  if (currentOption === option) {
    fetchNui("select", [option.targetType, option.targetId]);
  }
  resetHold();
}

export function resetHold() {
  isHolding = false;
  holdStartTime = null;
  clearTimeout(holdTimeout);
  progressElement.style.transition = "none";
  progressElement.style.height = "0";
}

function startHold(option) {
  if (isHolding) return;

  isHolding = true;
  holdStartTime = Date.now();
  progressElement.style.transition = `height ${option.holdTime}ms linear`;
  progressElement.style.height = "100%";

  holdTimeout = setTimeout(() => {
    completeHold(option);
  }, option.holdTime);
}

export function updateHighlight() {
  const options = optionsWrapper.querySelectorAll(".option-container");
  if (options.length > 0) {
    options.forEach(option => option.classList.remove("highlighted"));
    options[currentIndex].classList.add("highlighted");

    if (options[currentIndex].color) {
      const c = options[currentIndex].color
      const color = `rgb(${c[0]}, ${c[1]}, ${c[2]}, ${c[3] / 255})`
      document.body.style.setProperty('--theme-color', color)
    }else{
      document.body.style.setProperty('--theme-color', defaultColor)
    }
  }
}

window.addEventListener("wheel", (event) => {
  if (isHolding) return;
  
  const options = optionsWrapper.querySelectorAll(".option-container");
  if (options.length === 0) return;

  if (event.deltaY > 0) {
    currentIndex = setCurrentIndex((currentIndex + 1) % options.length);
  } else {
    currentIndex = setCurrentIndex((currentIndex - 1 + options.length) % options.length);
  }

  updateHighlight();

  fetchNui("currentOption", [currentIndex + 1]);
});

updateHighlight();


