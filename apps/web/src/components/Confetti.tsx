"use client";

import { useEffect, useRef } from "react";

type ConfettiProps = {
  trigger: number;
};

export function Confetti({ trigger }: ConfettiProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    if (trigger === 0) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const colors = [
      "#2563eb",
      "#3b82f6",
      "#60a5fa",
      "#14b8a6",
      "#ffffff",
      "#93c5fd",
    ];
    const particles: {
      x: number;
      y: number;
      vx: number;
      vy: number;
      radius: number;
      color: string;
      alpha: number;
      decay: number;
    }[] = [];

    // Patlama efektinde 100 partikül oluştur
    for (let i = 0; i < 100; i++) {
      particles.push({
        x: canvas.width / 2,
        y: canvas.height * 0.45,
        vx: (Math.random() - 0.5) * 16,
        vy: (Math.random() - 0.75) * 16 - 4,
        radius: Math.random() * 5 + 4,
        color: colors[Math.floor(Math.random() * colors.length)],
        alpha: 1,
        decay: Math.random() * 0.015 + 0.012,
      });
    }

    let animationFrameId: number;
    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      let active = false;

      particles.forEach((p) => {
        if (p.alpha <= 0) return;
        active = true;
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.38; // Yerçekimi
        p.vx *= 0.98; // Sürtünme
        p.alpha -= p.decay;

        ctx.save();
        ctx.globalAlpha = Math.max(0, p.alpha);
        ctx.fillStyle = p.color;
        ctx.beginPath();
        // Daire veya dikdörtgen partiküller
        if (Math.random() > 0.5) {
          ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        } else {
          ctx.rect(
            p.x - p.radius,
            p.y - p.radius,
            p.radius * 2,
            p.radius * 1.5,
          );
        }
        ctx.fill();
        ctx.restore();
      });

      if (active) {
        animationFrameId = requestAnimationFrame(render);
      }
    };

    render();
    return () => cancelAnimationFrame(animationFrameId);
  }, [trigger]);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 pointer-events-none z-50 h-full w-full"
    />
  );
}
