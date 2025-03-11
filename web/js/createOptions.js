import { updateHighlight, setCurrentIndex } from "./controls.js";

const optionsWrapper = document.getElementById("options-wrapper");

export function createOptions(type, data, id) {
  if (data.hide) return;

  const option = document.createElement("div");
  
  let iconClasses = "fa-fw";
  
  if (data.icon) {
    if  (data.icon.includes("fa-")) {
      iconClasses += ` ${data.icon}`;
    } else {
      iconClasses += ` fa-solid fa-${data.icon}`;
    }
  }


  const iconElement = `<i class="${iconClasses} option-icon" ${
    data.iconColor ? `style="color:${data.iconColor} !important"` : ""
  }></i>`;

  option.innerHTML = `
    <div class="animated-background"></div>
    ${iconElement}
    <p class="option-label">${data.label + (data.holdTime ? " (hold)" : "")}</p>
  `;
  option.className = "option-container";
  option.targetType = type;
  option.color = data.color;
  option.targetId = id;
  option.holdTime = data.holdTime || 0; // Default to 0 if no holdtime

  optionsWrapper.appendChild(option);

  if (optionsWrapper.children.length === 1) {
    setCurrentIndex(0);
    updateHighlight();
  }
}