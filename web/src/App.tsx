import React, { useState } from "react";
import { debugData } from "./utils/debugData";
import { useNuiEvent } from "./hooks/useNuiEvent";
import { InteractionData } from "./components/Interact";

import Interaction from "./components/Interact";

{
  debugData([
    {
      action: "setVisible",
      data: true,
    },
  ]);

  debugData([
    {
      action: "updateInteraction",
      data: {
        id: "123123",
        options: [
          { text: "do something", icon: "house", disable: true },
          { text: "world2", icon: "house" },
        ],
      },
    },
  ]);
}

const App: React.FC = () => {
  const [pause, setPause] = useState<boolean>(false);
  const [interaction, setInteraction] = useState<InteractionData>();

  useNuiEvent<boolean>("pause", (paused) => {
    setPause(paused);
  });

  useNuiEvent<InteractionData>("updateInteraction", (newInteraction) => {
    if (!newInteraction) return;
    setInteraction(newInteraction);
  });

  return <>{interaction && <Interaction interaction={interaction} />}</>;
};

export default App;
