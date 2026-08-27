let audioContext: AudioContext | null = null;

function getAudioContext(): AudioContext | null {
  if (typeof window === "undefined") return null;
  if (!audioContext) {
    const WebkitAudioContext = (window as Window & typeof globalThis & { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    audioContext = new (window.AudioContext || WebkitAudioContext)();
  }
  return audioContext;
}

export async function playCompletionSound(
  type: "chime" | "digital" | "bird" | "gong" = "chime"
): Promise<void> {
  const ctx = getAudioContext();
  if (!ctx) return;

  if (ctx.state === "suspended") {
    await ctx.resume();
  }

  const now = ctx.currentTime;

  if (type === "digital") {
    // Çift hızlı bip
    const playBeep = (time: number, duration: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(880, time);
      gain.gain.setValueAtTime(0.12, time);
      gain.gain.exponentialRampToValueAtTime(0.01, time + duration - 0.01);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(time);
      osc.stop(time + duration);
    };
    playBeep(now, 0.06);
    playBeep(now + 0.08, 0.1);
  } else if (type === "bird") {
    // Kuş cıvıltısı (Hızlı frekans kaymaları)
    const playChirp = (time: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(1500, time);
      osc.frequency.exponentialRampToValueAtTime(3200, time + 0.08);
      gain.gain.setValueAtTime(0.08, time);
      gain.gain.exponentialRampToValueAtTime(0.005, time + 0.08);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(time);
      osc.stop(time + 0.08);
    };
    playChirp(now);
    playChirp(now + 0.1);
    playChirp(now + 0.2);
  } else if (type === "gong") {
    // Kalın derin gong sesi
    const osc1 = ctx.createOscillator();
    const osc2 = ctx.createOscillator();
    const gain = ctx.createGain();
    
    osc1.type = "triangle";
    osc1.frequency.setValueAtTime(180, now);
    osc1.frequency.linearRampToValueAtTime(120, now + 1.2);
    
    osc2.type = "sine";
    osc2.frequency.setValueAtTime(182, now); // Hafif detune efekti
    osc2.frequency.linearRampToValueAtTime(121, now + 1.2);
    
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 1.2);
    
    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(ctx.destination);
    
    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 1.2);
    osc2.stop(now + 1.2);
  } else {
    // chime (Varsayılan melodik çan)
    const osc1 = ctx.createOscillator();
    const osc2 = ctx.createOscillator();
    const gain = ctx.createGain();

    osc1.type = "sine";
    osc1.frequency.setValueAtTime(523.25, now); // C5

    osc2.type = "sine";
    osc2.frequency.setValueAtTime(783.99, now); // G5

    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.8);

    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(ctx.destination);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.8);
    osc2.stop(now + 0.8);
  }
}
