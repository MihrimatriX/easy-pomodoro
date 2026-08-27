"use client";

import { ChevronDown, ChevronUp, Minus, Plus } from "lucide-react";
import { useT } from "@/context/LocaleContext";

type NeoStepperProps = {
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
  compact?: boolean;
  variant?: "default" | "pill";
  ariaLabel?: string;
};

export function NeoStepper({
  value,
  onChange,
  min = 1,
  max = 120,
  step = 1,
  compact = false,
  variant = "default",
  ariaLabel,
}: NeoStepperProps) {
  const t = useT();
  const label = ariaLabel ?? t("valueLabel");
  const clamp = (n: number) => Math.min(max, Math.max(min, n));

  const decrement = () => onChange(clamp(value - step));
  const increment = () => onChange(clamp(value + step));

  const rootClass =
    variant === "pill"
      ? "neo-stepper-pill"
      : compact
        ? "neo-stepper neo-stepper-compact"
        : "neo-stepper";

  if (compact || variant === "pill") {
    return (
      <div className={rootClass} aria-label={label}>
        <button
          type="button"
          onClick={decrement}
          disabled={value <= min}
          className="neo-stepper-btn"
          aria-label={t("decrease")}
        >
          <Minus size={14} strokeWidth={2.5} />
        </button>
        <span className="neo-stepper-value font-mono">{value}</span>
        <button
          type="button"
          onClick={increment}
          disabled={value >= max}
          className="neo-stepper-btn"
          aria-label={t("increase")}
        >
          <Plus size={14} strokeWidth={2.5} />
        </button>
      </div>
    );
  }

  return (
    <div className={rootClass} aria-label={label}>
      <span className="neo-stepper-value font-mono">{value}</span>
      <div className="neo-stepper-arrows">
        <button
          type="button"
          onClick={increment}
          disabled={value >= max}
          className="neo-stepper-arrow"
          aria-label={t("increase")}
        >
          <ChevronUp size={15} strokeWidth={2.5} />
        </button>
        <button
          type="button"
          onClick={decrement}
          disabled={value <= min}
          className="neo-stepper-arrow"
          aria-label={t("decrease")}
        >
          <ChevronDown size={15} strokeWidth={2.5} />
        </button>
      </div>
    </div>
  );
}
