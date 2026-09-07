const optionsList = document.getElementById("options-list");

export function createOptions(type, data, id) {
  if (data.hide) return;

  const option = document.createElement("div");

  let iconClasses = "fa-fw option-icon";

  if (data.icon) {
    if (data.icon.includes("fa-")) {
      iconClasses += ` ${data.icon}`;
    } else {
      iconClasses += ` fa-solid fa-${data.icon}`;
    }
  }

  const iconStyle = data.iconColor ? `style="color:${data.iconColor} !important"` : "";
  const holdMarkup = data.holdTime ? `<span class="option-hold">Hold</span>` : "";

  option.innerHTML = `
    <div class="animated-background"></div>
    <i class="${iconClasses}" ${iconStyle}></i>
    <p class="option-label">${data.label}</p>
    ${holdMarkup}
  `;
  option.className = "option-container";
  option.targetType = type;
  option.color = data.color;
  option.targetId = id;
  option.holdTime = data.holdTime || 0;
  option.hideButton = data.hideButton || false;

  optionsList.appendChild(option);
}
