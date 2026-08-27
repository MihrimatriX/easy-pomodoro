import { ImageResponse } from "next/og";

export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#e8eef8",
        }}
      >
        <div
          style={{
            width: 118,
            height: 118,
            borderRadius: 999,
            border: "14px solid #2563eb",
            borderRightColor: "#c5d0e4",
          }}
        />
      </div>
    ),
    { ...size },
  );
}
