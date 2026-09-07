import { createOptions } from "./createOptions.js";
import { fetchNui } from "./fetchNui.js";
import { onSelect, resetHold, setCurrentIndex, setDefaultColor, updateHighlight } from "./controls.js";
import { applyTheme } from "./theme.js";
import { setupBrowserMode } from "./browser.js";
import { setMenuConfig, setOptionCount } from "./menu.js";

const optionsList = document.getElementById("options-list");
const interactKeyEl = document.getElementById("interact-key");
const body = document.body;

let interactKeyLabel = "E";

function setInteractKey(label) {
  const text = String(label || "E").trim() || "E";
  interactKeyLabel = text;

  if (!interactKeyEl || body.classList.contains("is-cooldown")) return;

  interactKeyEl.textContent = text;
  interactKeyEl.classList.toggle("is-wide", text.length > 2);
}

function setInteractLabel(label) {
  const el = document.querySelector("#interact-summary .option-label");
  if (!el) return;
  el.textContent = String(label || "Interact").trim() || "Interact";
}

window.addEventListener("message", (event) => {
  switch (event.data.action) {
    case "visible": {
      body.style.visibility = event.data.value ? "visible" : "hidden";
      break;
    }

    case "setTheme": {
      applyTheme(event.data.value);
      updateHighlight();
      break;
    }

    case "setMenu": {
      setMenuConfig(event.data.value || {});
      updateHighlight();
      break;
    }

    case "setOptions": {
      optionsList.innerHTML = "";

      if (event.data.value.options) {
        for (const type in event.data.value.options) {
          event.data.value.options[type].forEach((data, id) => {
            createOptions(type, data, id + 1);
          });
        }
      }

      const count = optionsList.children.length;
      setOptionCount(count, { reset: !!event.data.value.resetIndex });
      if (event.data.value.resetIndex) setCurrentIndex(0);
      updateHighlight();
      break;
    }

    case "interact": {
      onSelect();
      break;
    }

    case "release": {
      resetHold();
      break;
    }

    case "setKey": {
      setInteractKey(event.data.value);
      break;
    }

    case "setLabel": {
      setInteractLabel(event.data.value);
      break;
    }

    case "setColor": {
      const c = event.data.value;
      if (!c) {
        setDefaultColor(null);
        break;
      }
      const color = `rgb(${c[0]}, ${c[1]}, ${c[2]}, ${c[3] / 255})`;
      setDefaultColor(color);
      break;
    }

    case "setCooldown": {
      body.classList.toggle("is-cooldown", !!event.data.value);
      if (!interactKeyEl) break;

      if (event.data.value) {
        interactKeyEl.classList.remove("is-wide");
        interactKeyEl.innerHTML = `<i class="fa-regular fa-hourglass-half"></i>`;
      } else {
        setInteractKey(interactKeyLabel);
      }
      break;
    }
  }
});

window.addEventListener("load", async () => {
  setupBrowserMode();
  await fetchNui("load");
});
