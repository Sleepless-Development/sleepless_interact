import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
import { isEnvBrowser } from "./utils/misc";

import { fas } from "@fortawesome/free-solid-svg-icons";
import { far } from "@fortawesome/free-regular-svg-icons";
import { fab } from "@fortawesome/free-brands-svg-icons";
import { library } from "@fortawesome/fontawesome-svg-core";

library.add(fas, far, fab);
const root = document.getElementById("root");

if (isEnvBrowser()) {
  // https://i.imgur.com/iPTAdYV.png - Night time img
  root!.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")';
  root!.style.backgroundSize = "cover";
  root!.style.backgroundRepeat = "no-repeat";
  root!.style.backgroundPosition = "center";
}

createRoot(root!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
