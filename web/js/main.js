import { createOptions } from "./createOptions.js";
import { fetchNui } from "./fetchNui.js";
import { onSelect } from "./controls.js";
import { setCurrentIndex, resetHold, setDefaultColor } from "./controls.js";

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;

window.addEventListener("message", (event) => {
  switch (event.data.action) {
    case "visible": {
      body.style.visibility = event.data.value ? "visible" : "hidden";
      break
    }

    case "setOptions": {
      optionsWrapper.innerHTML = "";

      if (event.data.value.options) {
        for (const type in event.data.value.options) {
          event.data.value.options[type].forEach((data, id) => {
            createOptions(type, data, id + 1);
          });
        }
        if (event.data.value.resetIndex) {
          setCurrentIndex(0);
        }
      }
      break
    }

    case "interact": {
      onSelect();
      break
    }

    case "release": {
      resetHold();
      break
    }

    case "setColor": {
      const c = event.data.value
      const color = `rgb(${c[0]}, ${c[1]}, ${c[2]}, ${c[3] / 255})`
      setDefaultColor(color)
      body.style.setProperty('--theme-color', color)
      break
    }

    case "setCooldown": {
      body.style.opacity = event.data.value ? '0.3' : '1'
      const interactKey = document.getElementById("interact-key");

      interactKey.innerHTML = event.data.value ?  `<i class="fa-regular fa-hourglass-half"></i>` : 'E'

      break
    }
  }
});

window.addEventListener("load", async (event) => {
  await fetchNui("load");
});