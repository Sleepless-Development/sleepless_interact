import React, {
  useState,
  useEffect,
  useCallback,
  useMemo,
  useRef,
} from "react";
import styles from "../modules/Interact.module.css";
import { fetchNui } from "../utils/fetchNui";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { IconProp } from "@fortawesome/fontawesome-svg-core";

type Option = { text: string; icon: IconProp; disable: boolean | null };
export interface InteractionData {
  id: string;
  options: Option[];
}

const Interaction: React.FC<{
  interaction: InteractionData;
  color: string;
}> = ({ interaction, color }) => {
  const { id, options } = interaction;
  const [currentOption, setCurrentOption] = useState(0);
  const maxOptions = options.length;
  const lastActive = useRef<number | null>(null);

  const updateOption = useCallback(
    (direction: "up" | "down") => {
      if (!options || options.length === 0) return;

      if (maxOptions == 0) return;
      let indexChange = direction === "up" ? -1 : 1;
      let newOption = (currentOption + indexChange + maxOptions) % maxOptions;

      let tries = 0;
      while (options[newOption].disable && tries < maxOptions) {
        tries++;
        newOption = (newOption + indexChange + maxOptions) % maxOptions;
      }
      lastActive.current = currentOption;
      setCurrentOption(newOption);
      fetchNui("setCurrentTextOption", { index: newOption + 1 });
    },
    [currentOption, options]
  );

  useEffect(() => {
    if (options.length > 0 && options[0].disable) {
      updateOption("down");
    } else {
      setCurrentOption(0);
      fetchNui("setCurrentTextOption", { index: 1 });
    }
  }, [options]);

  useEffect(() => {
    const handleKeyPress = (event: KeyboardEvent) => {
      if (event.key === "ArrowUp" || event.key === "ArrowDown") {
        updateOption(event.key === "ArrowUp" ? "up" : "down");
      }
    };

    const handleWheel = (event: WheelEvent) => {
      updateOption(event.deltaY < 0 ? "up" : "down");
    };

    window.addEventListener("keydown", handleKeyPress);
    window.addEventListener("wheel", handleWheel, { passive: true });

    return () => {
      window.removeEventListener("keydown", handleKeyPress);
      window.removeEventListener("wheel", handleWheel);
    };
  }, [updateOption]);

  const numberOfActiveOptions = useMemo(
    () => options.filter((option) => !option.disable).length,
    [options]
  );

  const OptionButton = ({
    text,
    icon,
    isActive,
    wasActive,
  }: {
    text: string;
    icon: IconProp;
    isActive: boolean;
    wasActive: boolean;
  }) => (
    <>
      <div
        style={{
          translate: numberOfActiveOptions < 2 ? "-1.5rem" : "",
        }}
        className={styles.button}
      >
        <div
          className={`${styles.innerButton} ${isActive && styles.active} ${
            wasActive && styles.wasActive
          }`}
        ></div>

        {numberOfActiveOptions > 1 && isActive && (
          <FontAwesomeIcon icon={"caret-right"} className={styles.indicator} />
        )}
        {icon && <FontAwesomeIcon icon={icon} className={styles.buttonIcon} />}
        <div className={styles.buttonText}>{text}</div>
      </div>
    </>
  );

  const renderOptions = () => {
    if (!options || typeof options === "string") return null;

    return options.map(
      (option, index) =>
        !option.disable && (
          <OptionButton
            key={index}
            text={option.text}
            icon={option.icon}
            isActive={currentOption === index}
            wasActive={typeof lastActive == "number" && lastActive === index}
          />
        )
    );
  };

  return (
    <>
      <div className={styles.container} style={{ color: color }}>
        <div className={styles.interactKey}>
          <div>E</div>
        </div>
        <div className={styles.ButtonsContainer}>{renderOptions()}</div>
      </div>
    </>
  );
};

export default Interaction;
