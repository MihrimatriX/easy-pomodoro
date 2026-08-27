import { ImageResponse } from "next/og";
import { APP_DESCRIPTION, APP_NAME, APP_TAGLINE } from "@shared/app-copy";

export const alt = `${APP_NAME} — ${APP_TAGLINE}`;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 72,
          background:
            "linear-gradient(145deg, #eef3fb 0%, #dce6f7 55%, #cfdcfc 100%)",
          color: "#152a45",
          fontFamily: "ui-sans-serif, system-ui, sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <div
            style={{
              width: 72,
              height: 72,
              borderRadius: 20,
              background: "#e8eef8",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              boxShadow: "8px 8px 16px #b8c4d8, -8px -8px 16px #f5f8fc",
            }}
          >
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 999,
                border: "5px solid #2563eb",
                borderRightColor: "#c5d0e4",
              }}
            />
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.5 }}>
            {APP_NAME}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div
            style={{
              fontSize: 58,
              fontWeight: 800,
              letterSpacing: -1.6,
              lineHeight: 1.12,
              maxWidth: 980,
            }}
          >
            {APP_TAGLINE}
          </div>
          <div style={{ fontSize: 26, color: "#4a5c72", maxWidth: 900 }}>
            {APP_DESCRIPTION}
          </div>
        </div>

        <div
          style={{
            display: "flex",
            gap: 16,
            fontSize: 22,
            fontWeight: 600,
            color: "#2563eb",
          }}
        >
          <span>Odak</span>
          <span>·</span>
          <span>Görevler</span>
          <span>·</span>
          <span>Alışkanlıklar</span>
        </div>
      </div>
    ),
    { ...size },
  );
}
