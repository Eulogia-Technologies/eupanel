"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { sidebarByRole, DashboardRole } from "@/lib/dashboard-nav";
import {
  IconHome, IconGlobe, IconMail, IconDatabase, IconDns,
  IconShield, IconUsers, IconBuilding, IconLink, IconCreditCard,
  IconList, IconServer, IconCpu, IconQueue, IconArchive,
  IconSettings, IconBarChart, IconPuzzle, IconActivity,
  IconFolder, IconClock, IconLogout, IconUser, IconChevronRight,
} from "@/components/ui/icons";

type SidebarProps = {
  role: DashboardRole;
  onLogout: () => void;
};

// Map nav labels to icons
const ICON_MAP: Record<string, React.ComponentType<{ size?: number; className?: string }>> = {
  "Home": IconHome,
  "Websites & Domains": IconGlobe,
  "Mail": IconMail,
  "Databases": IconDatabase,
  "DNS Settings": IconDns,
  "SSL/TLS Certificates": IconShield,
  "Customers": IconUsers,
  "Resellers": IconBuilding,
  "Domains": IconLink,
  "Subscriptions": IconCreditCard,
  "Service Plans": IconList,
  "Servers": IconServer,
  "Runtimes": IconCpu,
  "Jobs": IconQueue,
  "Backups": IconArchive,
  "Tools & Settings": IconSettings,
  "Statistics": IconBarChart,
  "Extensions": IconPuzzle,
  "Monitoring": IconActivity,
  "File Manager": IconFolder,
  "Scheduled Tasks": IconClock,
  "Jobs Queue": IconQueue,
};

type StoredUser = { name?: string; email?: string; role?: string };

export function DashboardSidebar({ role, onLogout }: SidebarProps) {
  const groups = sidebarByRole[role];
  const pathname = usePathname();
  const [user, setUser] = useState<StoredUser | null>(null);

  useEffect(() => {
    try {
      const raw = localStorage.getItem("eupanel_user");
      if (raw) setUser(JSON.parse(raw) as StoredUser);
    } catch { /* ignore */ }
  }, []);

  function isActive(href: string) {
    if (href === "/dashboard" && role === "customer") return pathname === "/dashboard";
    if (href === `/dashboard/${role}` && role !== "customer") return pathname === `/dashboard/${role}`;
    return pathname === href;
  }

  const initials = user?.name
    ? user.name.split(" ").map((p) => p[0]).slice(0, 2).join("").toUpperCase()
    : role.slice(0, 2).toUpperCase();

  const profileHref = role === "customer" ? "/dashboard/profile" : `/dashboard/${role}/profile`;

  return (
    <aside className="ep-sidebar">
      {/* Brand */}
      <div className="ep-sidebar-brand">
        <span className="ep-sidebar-brand-name">eupanel</span>
        <span className="ep-sidebar-brand-badge">{role}</span>
      </div>

      {/* Navigation */}
      <nav className="ep-sidebar-nav">
        {groups.map((group, gi) => (
          <div key={gi}>
            {group.title ? (
              <div className="ep-sidebar-section">{group.title}</div>
            ) : null}
            {group.items.map((item) => {
              const Icon = ICON_MAP[item.label] ?? IconChevronRight;
              const active = isActive(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`ep-nav-link${active ? " active" : ""}`}
                >
                  <Icon size={15} className="ep-nav-icon" />
                  <span style={{ flex: 1 }}>{item.label}</span>
                  {item.count != null && (
                    <span className="count">{item.count}</span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="ep-sidebar-footer">
        {/* User info */}
        {user && (
          <div className="ep-sidebar-footer-user">
            <div className="ep-sidebar-avatar">{initials}</div>
            <div className="ep-sidebar-user-info">
              <div className="ep-sidebar-user-name ep-truncate">
                {user.name ?? "User"}
              </div>
              <div className="ep-sidebar-user-role">{role}</div>
            </div>
          </div>
        )}

        <Link href={profileHref} className="ep-sidebar-btn">
          <IconUser size={14} />
          My Profile
        </Link>

        <button className="ep-sidebar-btn" onClick={onLogout}>
          <IconLogout size={14} />
          Sign out
        </button>
      </div>
    </aside>
  );
}
