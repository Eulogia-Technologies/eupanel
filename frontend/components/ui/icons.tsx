import type { ReactNode } from "react";

type IconProps = { className?: string; size?: number };

const ico = (d: string | ReactNode, viewBox = "0 0 16 16") =>
  function Icon({ className = "", size = 16 }: IconProps) {
    return (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox={viewBox}
        width={size}
        height={size}
        fill="none"
        stroke="currentColor"
        strokeWidth={1.5}
        strokeLinecap="round"
        strokeLinejoin="round"
        className={className}
        aria-hidden
      >
        {typeof d === "string" ? <path d={d} /> : d}
      </svg>
    );
  };

export const IconHome = ico(
  "M2 6.5 8 2l6 4.5V14a1 1 0 0 1-1 1H9.5v-4h-3v4H3a1 1 0 0 1-1-1z"
);

export const IconGlobe = ico(
  <>
    <circle cx="8" cy="8" r="6" />
    <path d="M8 2a10 10 0 0 1 0 12M8 2a10 10 0 0 0 0 12M2 8h12" />
  </>
);

export const IconDatabase = ico(
  <>
    <ellipse cx="8" cy="4.5" rx="5" ry="2" />
    <path d="M3 4.5v3c0 1.1 2.24 2 5 2s5-.9 5-2v-3" />
    <path d="M3 7.5v3c0 1.1 2.24 2 5 2s5-.9 5-2v-3" />
  </>
);

export const IconMail = ico(
  <>
    <rect x="2" y="4" width="12" height="9" rx="1.5" />
    <path d="m2 4.5 6 4 6-4" />
  </>
);

export const IconShield = ico(
  <>
    <path d="M8 2 3 4.5v4c0 2.8 2 5 5 5.5 3-.5 5-2.7 5-5.5v-4z" />
    <path d="m5.5 8 1.8 1.8L10.5 6" />
  </>
);

export const IconServer = ico(
  <>
    <rect x="2" y="3" width="12" height="4" rx="1" />
    <rect x="2" y="9" width="12" height="4" rx="1" />
    <circle cx="5" cy="5" r="0.75" fill="currentColor" stroke="none" />
    <circle cx="5" cy="11" r="0.75" fill="currentColor" stroke="none" />
  </>
);

export const IconCpu = ico(
  <>
    <rect x="4" y="4" width="8" height="8" rx="1" />
    <path d="M6 2v2M8 2v2M10 2v2M6 12v2M8 12v2M10 12v2M2 6h2M2 8h2M2 10h2M12 6h2M12 8h2M12 10h2" />
  </>
);

export const IconQueue = ico(
  <path d="M2 4h12M2 8h8M2 12h10" />
);

export const IconArchive = ico(
  <>
    <rect x="2" y="3" width="12" height="3" rx="0.75" />
    <path d="M3 6v6a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V6" />
    <path d="M6.5 9h3" />
  </>
);

export const IconUsers = ico(
  <>
    <circle cx="6" cy="5.5" r="2.5" />
    <path d="M1 13.5c0-2.2 2.24-4 5-4" />
    <circle cx="11" cy="5.5" r="2" />
    <path d="M11 9.5c1.93 0 3.5 1.57 3.5 3.5" />
  </>
);

export const IconBuilding = ico(
  <>
    <rect x="2" y="2" width="7" height="12" rx="0.75" />
    <rect x="9" y="6" width="5" height="8" rx="0.75" />
    <path d="M5 5h1M5 8h1M5 11h1M11 9h1M11 12h1" />
  </>
);

export const IconLink = ico(
  <>
    <path d="M6 10a3 3 0 0 0 4 0l2-2a3 3 0 0 0-4-4L6.5 5.5" />
    <path d="M10 6a3 3 0 0 0-4 0L4 8a3 3 0 0 0 4 4l1.5-1.5" />
  </>
);

export const IconCreditCard = ico(
  <>
    <rect x="2" y="4.5" width="12" height="8" rx="1.25" />
    <path d="M2 7.5h12" />
    <path d="M5 10.5h2" />
  </>
);

export const IconList = ico(
  <path d="M4 4h8M4 8h8M4 12h8M2 4h.5M2 8h.5M2 12h.5" />
);

export const IconSettings = ico(
  <>
    <circle cx="8" cy="8" r="2" />
    <path d="M8 2v1.5M8 12.5V14M2 8h1.5M12.5 8H14M3.75 3.75l1 1M11.25 11.25l1 1M3.75 12.25l1-1M11.25 4.75l1-1" />
  </>
);

export const IconBarChart = ico(
  <path d="M3 12V8M7 12V5M11 12V9M13 12H3" />
);

export const IconPuzzle = ico(
  <>
    <path d="M6 3a1 1 0 0 1 2 0v1h3a1 1 0 0 1 1 1v3h1a1 1 0 0 1 0 2h-1v3a1 1 0 0 1-1 1H8v1a1 1 0 0 1-2 0v-1H3a1 1 0 0 1-1-1V9H1a1 1 0 0 1 0-2h1V5a1 1 0 0 1 1-1h3z" />
  </>
);

export const IconActivity = ico(
  <path d="M1 8h3l2-5 2 10 2-7 1.5 2H15" />
);

export const IconFolder = ico(
  <>
    <path d="M2 5a1 1 0 0 1 1-1h3l1.5 2H13a1 1 0 0 1 1 1v5a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1z" />
  </>
);

export const IconClock = ico(
  <>
    <circle cx="8" cy="8" r="6" />
    <path d="M8 5v3.5l2 2" />
  </>
);

export const IconSearch = ico(
  <>
    <circle cx="7" cy="7" r="4.5" />
    <path d="M10.5 10.5 14 14" />
  </>
);

export const IconPlus = ico(
  <path d="M8 3v10M3 8h10" />
);

export const IconX = ico(
  <path d="M4 4l8 8M12 4l-8 8" />
);

export const IconCheck = ico(
  <path d="M3 8l3.5 3.5L13 4.5" />
);

export const IconLogout = ico(
  <>
    <path d="M6 3H3a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h3" />
    <path d="M10 5l3 3-3 3M13 8H6" />
  </>
);

export const IconUser = ico(
  <>
    <circle cx="8" cy="5.5" r="3" />
    <path d="M2.5 14c0-2.76 2.46-5 5.5-5s5.5 2.24 5.5 5" />
  </>
);

export const IconDns = ico(
  <>
    <rect x="2" y="2" width="12" height="4" rx="1" />
    <path d="M5 4h.5M2 8h12M5 10h.5M2 14h12M5 16h.5" />
    <rect x="2" y="8" width="12" height="4" rx="1" />
  </>
);

export const IconChevronRight = ico(
  <path d="M6 4l4 4-4 4" />
);

export const IconRefresh = ico(
  <path d="M13 8A5 5 0 1 1 8.5 3.05M13 3v5h-5" />
);

export const IconEllipsis = ico(
  <>
    <circle cx="4" cy="8" r="1" fill="currentColor" stroke="none" />
    <circle cx="8" cy="8" r="1" fill="currentColor" stroke="none" />
    <circle cx="12" cy="8" r="1" fill="currentColor" stroke="none" />
  </>
);

export const IconTrash = ico(
  <>
    <path d="M3 5h10M5 5V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1" />
    <path d="M4 5l.75 8a1 1 0 0 0 1 .9h4.5a1 1 0 0 0 1-.9L12 5" />
  </>
);
