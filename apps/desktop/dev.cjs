const { spawn } = require("child_process");
const path = require("path");

const root = path.resolve(__dirname, "../..");
const WEB = "http://localhost:3000";

async function webUp() {
  try {
    const res = await fetch(WEB);
    return res.ok;
  } catch {
    return false;
  }
}

async function waitForWeb() {
  for (let i = 0; i < 80; i += 1) {
    if (await webUp()) return;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error("Web server did not start at " + WEB);
}

async function main() {
  let child;
  if (!(await webUp())) {
    child = spawn("npm", ["run", "dev", "-w", "@easy-pomodoro/web"], {
      cwd: root,
      stdio: "inherit",
      shell: true,
    });
  }
  await waitForWeb();
  const electron = spawn("npm", ["run", "dev", "-w", "@easy-pomodoro/desktop"], {
    cwd: root,
    stdio: "inherit",
    shell: true,
    env: { ...process.env, EASY_POMODORO_URL: WEB },
  });
  electron.on("exit", (code) => {
    if (child) child.kill();
    process.exit(code ?? 0);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
