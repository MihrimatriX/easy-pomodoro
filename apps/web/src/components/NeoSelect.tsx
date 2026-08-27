"use client";

import {
  Children,
  isValidElement,
  useEffect,
  useId,
  useRef,
  useState,
  type ReactElement,
  type ReactNode,
} from "react";
import { ChevronDown } from "lucide-react";
import { useT } from "@/context/LocaleContext";

type NeoSelectProps = {
  value: string;
  onChange: (value: string) => void;
  children: ReactNode;
  className?: string;
  ariaLabel?: string;
};

type SelectOption = { value: string; label: string };

function optionsFromChildren(children: ReactNode): SelectOption[] {
  const options: SelectOption[] = [];
  Children.forEach(children, (child) => {
    if (isValidElement(child) && child.type === "option") {
      const el = child as ReactElement<{
        value?: string | number;
        children?: ReactNode;
      }>;
      options.push({
        value: String(el.props.value ?? ""),
        label: String(el.props.children ?? ""),
      });
    }
  });
  return options;
}

export function NeoSelect({
  value,
  onChange,
  children,
  className = "",
  ariaLabel,
}: NeoSelectProps) {
  const t = useT();
  const [open, setOpen] = useState(false);
  const wrapRef = useRef<HTMLDivElement>(null);
  const listId = useId();
  const options = optionsFromChildren(children);
  const selected = options.find((o) => o.value === value) ?? options[0];

  useEffect(() => {
    if (!open) return;
    const onPointerDown = (e: MouseEvent) => {
      if (!wrapRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [open]);

  return (
    <div ref={wrapRef} className={`neo-select-wrap ${className}`}>
      <button
        type="button"
        aria-label={ariaLabel}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={listId}
        className="neo-select-trigger"
        onClick={() => setOpen((prev) => !prev)}
      >
        <span className="neo-select-value">
          {selected?.label ?? t("selectPlaceholder")}
        </span>
        <ChevronDown
          size={15}
          strokeWidth={2.5}
          className={`neo-select-chevron shrink-0 text-muted transition-transform ${open ? "rotate-180" : ""}`}
          aria-hidden
        />
      </button>

      {open && (
        <ul
          id={listId}
          className="neo-select-menu"
          role="listbox"
          aria-label={ariaLabel}
        >
          {options.map((opt) => {
            const isSelected = opt.value === value;
            return (
              <li key={opt.value} role="presentation">
                <button
                  type="button"
                  role="option"
                  aria-selected={isSelected}
                  className={`neo-select-option ${isSelected ? "selected" : ""}`}
                  onClick={() => {
                    onChange(opt.value);
                    setOpen(false);
                  }}
                >
                  {opt.label}
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
