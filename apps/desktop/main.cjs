const { app, BrowserWindow } = require("electron");

const WEB_URL = process.env.EASY_POMODORO_URL || "http://localhost:3000";

function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 390,
    minHeight: 700,
    title: "Neo Pomodoro",
    autoHideMenuBar: true,
    backgroundColor: "#e8eef8",
  });
  win.loadURL(WEB_URL);
}

app.whenReady().then(() => {
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
