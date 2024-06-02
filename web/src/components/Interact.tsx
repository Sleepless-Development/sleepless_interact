import React, { useState, useEffect, useCallback, useMemo } from "react";
import styles from "../modules/Interact.module.css";
import { MdOutlineHexagon, MdHexagon } from "react-icons/md";
import { TbSquareLetterE } from "react-icons/tb";
import { fetchNui } from "../utils/fetchNui";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { IconProp } from "@fortawesome/fontawesome-svg-core";
import { useNuiEvent } from "../hooks/useNuiEvent";

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
  }: {
    text: string;
    icon: IconProp;
    isActive: boolean;
  }) => (
    <>
      <div
        style={{
          translate: numberOfActiveOptions < 2 ? "-1.5rem" : ""
        }}
        className={`${styles.button} ${isActive && styles.active}`}
      >
        {numberOfActiveOptions > 1 && (
          <div className={styles.indicator}>
            {isActive && <div className={styles.indicatorLight}></div>}
          </div>
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
          />
        )
    );
  };

  return (
    <>
      <div className={styles.container} style={{color: color}}>
        <div className={styles.interactKey}><div>E</div></div>
        <div className={styles.ButtonsContainer}>{renderOptions()}</div>
      </div>
    </>
  );
};

export default Interaction;
