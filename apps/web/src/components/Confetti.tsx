"use client";

import { useEffect, useRef } from "react";

type ConfettiProps = {
  trigger: number;
};

type Particle = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  color: string;
  alpha: number;
  decay: number;
  round: boolean;
  spin: number;
  angle: number;
};

/** Theme-aware palette: accent + phase colours + white sparkle. */
function themeColors(): string[] {
  const css = getComputedStyle(document.documentElement);
  const pick = (name: string) => css.getPropertyValue(name).trim();
  const colors = [
    pick("--accent"),
    pick("--accent-hover"),
    pick("--phase-short"),
    pick("--phase-long"),
    "#ffffff",
  ].filter(Boolean);
  return colors.length > 1 ? colors : ["#2563eb", "#14b8a6", "#6366f1", "#ffffff"];
}

export function Confetti({ trigger }: ConfettiProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    if (trigger === 0) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const width = window.innerWidth;
    const height = window.innerHeight;
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const colors = themeColors();
    const particles: Particle[] = Array.from({ length: 90 }, () => ({
      x: width / 2,
      y: height * 0.45,
      vx: (Math.random() - 0.5) * 16,
      vy: (Math.random() - 0.75) * 16 - 4,
      radius: Math.random() * 4 + 3,
      color: colors[Math.floor(Math.random() * colors.length)],
      alpha: 1,
      decay: Math.random() * 0.015 + 0.012,
      // Shape is fixed per particle (it used to be re-rolled every frame,
      // which made the confetti flicker between circles and squares).
      round: Math.random() > 0.5,
      spin: (Math.random() - 0.5) * 0.3,
      angle: Math.random() * Math.PI,
    }));

    let animationFrameId = 0;
    const render = () => {
      ctx.clearRect(0, 0, width, height);
      let active = false;

      for (const p of particles) {
        if (p.alpha <= 0) continue;
        active = true;
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.38; // gravity
        p.vx *= 0.98; // drag
        p.angle += p.spin;
        p.alpha -= p.decay;

        ctx.save();
        ctx.globalAlpha = Math.max(0, p.alpha);
        ctx.fillStyle = p.color;
        ctx.translate(p.x, p.y);
        ctx.rotate(p.angle);
        ctx.beginPath();
        if (p.round) {
          ctx.arc(0, 0, p.radius, 0, Math.PI * 2);
        } else {
          ctx.rect(-p.radius, -p.radius * 0.75, p.radius * 2, p.radius * 1.5);
        }
        ctx.fill();
        ctx.restore();
      }

      if (active) {
        animationFrameId = requestAnimationFrame(render);
      } else {
        ctx.clearRect(0, 0, width, height);
      }
    };

    render();
    return () => {
      cancelAnimationFrame(animationFrameId);
      ctx.clearRect(0, 0, width, height);
    };
  }, [trigger]);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden
      className="fixed inset-0 pointer-events-none z-50 h-full w-full"
    />
  );
}
