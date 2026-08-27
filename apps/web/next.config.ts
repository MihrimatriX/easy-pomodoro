import type { NextConfig } from "next";
import path from "node:path";
import withSerwistInit from "@serwist/next";

const desktopShell = Boolean(process.env.TAURI || process.env.ELECTRON);

const withSerwist = withSerwistInit({
  swSrc: "src/app/sw.ts",
  swDest: "public/sw.js",
  disable: process.env.NODE_ENV === "development" || desktopShell,
});

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: ["@easy-pomodoro/shared"],
  output: desktopShell ? "export" : "standalone",
  outputFileTracingRoot: path.join(__dirname, "../.."),
};

export default withSerwist(nextConfig);
