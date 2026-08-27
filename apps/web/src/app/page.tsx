import { AppShell } from "@/components/AppShell";
import {
  APP_DESCRIPTION,
  APP_HIGHLIGHTS,
  APP_NAME,
  APP_PILLARS,
  APP_TAGLINE,
} from "@shared/app-copy";
import "@shared/self-check";

export default function Home() {
  return (
    <>
      <header className="sr-only">
        <h1>{APP_NAME}</h1>
        <p>{APP_TAGLINE}</p>
        <p>{APP_DESCRIPTION}</p>
        <ul>
          {APP_PILLARS.map((item) => (
            <li key={item.id}>
              <strong>{item.title}</strong> — {item.description}
            </li>
          ))}
        </ul>
        <p>{APP_HIGHLIGHTS.map((item) => item.label).join(" · ")}</p>
      </header>
      <AppShell />
    </>
  );
}
