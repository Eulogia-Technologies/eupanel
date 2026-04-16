import { ActionIconName } from "@/components/websites-domains/types";

export function ActionIcon({ name }: { name: ActionIconName }) {
  const p = { viewBox: "0 0 24 24", width: 15, height: 15, fill: "none", stroke: "currentColor", strokeWidth: 1.75, strokeLinecap: "round" as const, strokeLinejoin: "round" as const };

  switch (name) {
    case "dashboard":
      return <svg {...p}><rect x="3" y="3" width="8" height="8" rx="1" /><rect x="13" y="3" width="8" height="5" rx="1" /><rect x="13" y="10" width="8" height="11" rx="1" /><rect x="3" y="13" width="8" height="8" rx="1" /></svg>;
    case "dns":
      return <svg {...p}><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18" /></svg>;
    case "mail":
      return <svg {...p}><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m4 7 8 6 8-6" /></svg>;
    case "rocket":
      return <svg {...p}><path d="M5 15c0-6 5-10 14-10 0 9-4 14-10 14l-4 1 1-5Z" /><circle cx="14" cy="10" r="1.5" /></svg>;
    case "folder":
      return <svg {...p}><path d="M3 7a2 2 0 0 1 2-2h5l2 2h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" /></svg>;
    case "database":
      return <svg {...p}><ellipse cx="12" cy="5" rx="8" ry="3" /><path d="M4 5v7c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 12v7c0 1.7 3.6 3 8 3s8-1.3 8-3v-7" /></svg>;
    case "ftp":
      return <svg {...p}><path d="m7 7 4-4 4 4M11 3v12M17 17l-4 4-4-4M13 21V9" /></svg>;
    case "backup":
      return <svg {...p}><path d="M3 12a9 9 0 1 0 3-6.7" /><path d="M3 3v6h6" /></svg>;
    case "copy":
      return <svg {...p}><rect x="9" y="9" width="11" height="11" rx="2" /><rect x="4" y="4" width="11" height="11" rx="2" /></svg>;
    case "logs":
      return <svg {...p}><path d="M8 6h13M8 12h13M8 18h13" /><path d="M3 6h.01M3 12h.01M3 18h.01" /></svg>;
    case "git":
      return <svg {...p}><path d="M12 3v8M12 11a3 3 0 1 0 3 3M12 11a3 3 0 1 1-3 3" /><circle cx="12" cy="3" r="2" /><circle cx="9" cy="14" r="2" /><circle cx="15" cy="14" r="2" /></svg>;
    case "wordpress":
      return <svg {...p}><circle cx="12" cy="12" r="9" /><path d="m7 8 2 8 3-10 3 10 2-8" /></svg>;
    case "composer":
      return <svg {...p}><path d="M4 7h16M4 12h16M4 17h10" /></svg>;
    case "seo":
      return <svg {...p}><circle cx="11" cy="11" r="6" /><path d="m20 20-4.2-4.2" /></svg>;
    case "import":
      return <svg {...p}><path d="M12 3v12M7 8l5-5 5 5M5 21h14" /></svg>;
    case "speed":
      return <svg {...p}><path d="M5 16a7 7 0 1 1 14 0" /><path d="m12 12 4-3" /></svg>;
    case "insights":
      return <svg {...p}><path d="M4 19V9M10 19V5M16 19v-7M22 19V3" /></svg>;
    case "php":
      return <svg {...p}><ellipse cx="12" cy="12" rx="9" ry="5" /><path d="M6 12h12" /></svg>;
    case "deploy":
      return <svg {...p}><path d="M12 3v12M7 8l5-5 5 5" /><rect x="4" y="17" width="16" height="4" rx="1" /></svg>;
    default:
      return null;
  }
}
