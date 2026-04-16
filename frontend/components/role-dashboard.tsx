"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { DashboardSidebar } from "@/components/dashboard-sidebar";
import {
  IconGlobe, IconDatabase, IconShield, IconQueue,
  IconServer, IconArchive, IconMail, IconDns,
  IconActivity, IconCheck,
} from "@/components/ui/icons";

type RoleDashboardProps = {
  expectedRole: "admin" | "customer" | "reseller";
  title: string;
  modules: string[];
};

type StoredUser = { name?: string; email?: string; role?: string };

type Job = {
  id: string;
  type: string;
  status: "pending" | "running" | "success" | "failed";
  targetType?: string;
};

const STATUS_BADGE: Record<string, { cls: string; label: string }> = {
  success:      { cls: "ep-badge ep-badge-success", label: "success" },
  running:      { cls: "ep-badge ep-badge-info",    label: "running" },
  pending:      { cls: "ep-badge ep-badge-pending", label: "pending" },
  failed:       { cls: "ep-badge ep-badge-error",   label: "failed"  },
  active:       { cls: "ep-badge ep-badge-success", label: "active"  },
  provisioning: { cls: "ep-badge ep-badge-warning", label: "provisioning" },
};

function StatusBadge({ status }: { status: string }) {
  const s = STATUS_BADGE[status] ?? { cls: "ep-badge ep-badge-neutral", label: status };
  return <span className={s.cls}>{s.label}</span>;
}

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

type QuickAction = {
  label: string;
  desc: string;
  href: string;
  Icon: React.ComponentType<{ size?: number; className?: string }>;
  color: string;
};

const QUICK_ACTIONS: Record<string, QuickAction[]> = {
  admin: [
    { label: "Servers",    desc: "Manage nodes",    href: "/dashboard/admin/servers",          Icon: IconServer,   color: "#0D9970" },
    { label: "Sites",      desc: "Websites & DNS",  href: "/dashboard/admin/websites-domains", Icon: IconGlobe,    color: "#2563EB" },
    { label: "Databases",  desc: "DB instances",    href: "/dashboard/admin/databases",        Icon: IconDatabase, color: "#7C3AED" },
    { label: "Jobs",       desc: "Task queue",      href: "/dashboard/admin/jobs",             Icon: IconQueue,    color: "#D97706" },
    { label: "Backups",    desc: "Snapshots",       href: "/dashboard/admin/backups",          Icon: IconArchive,  color: "#DC2626" },
    { label: "Monitoring", desc: "System health",   href: "/dashboard/admin/monitoring",       Icon: IconActivity, color: "#0891B2" },
  ],
  customer: [
    { label: "Websites",   desc: "Sites & domains", href: "/dashboard/websites-domains", Icon: IconGlobe,    color: "#2563EB" },
    { label: "Databases",  desc: "DB instances",    href: "/dashboard/databases",        Icon: IconDatabase, color: "#7C3AED" },
    { label: "Mail",       desc: "Email accounts",  href: "/dashboard/mail",             Icon: IconMail,     color: "#0D9970" },
    { label: "DNS",        desc: "Zone records",    href: "/dashboard/dns-settings",     Icon: IconDns,      color: "#D97706" },
    { label: "SSL",        desc: "Certificates",    href: "/dashboard/ssl-certificates", Icon: IconShield,   color: "#16A34A" },
    { label: "Backups",    desc: "Snapshots",       href: "/dashboard/backups",          Icon: IconArchive,  color: "#DC2626" },
  ],
  reseller: [
    { label: "Websites",   desc: "Sites & domains", href: "/dashboard/reseller/websites-domains", Icon: IconGlobe,    color: "#2563EB" },
    { label: "Databases",  desc: "DB instances",    href: "/dashboard/reseller/databases",        Icon: IconDatabase, color: "#7C3AED" },
    { label: "Mail",       desc: "Email accounts",  href: "/dashboard/reseller/mail",             Icon: IconMail,     color: "#0D9970" },
    { label: "DNS",        desc: "Zone records",    href: "/dashboard/reseller/dns-settings",     Icon: IconDns,      color: "#D97706" },
    { label: "SSL",        desc: "Certificates",    href: "/dashboard/reseller/ssl-certificates", Icon: IconShield,   color: "#16A34A" },
    { label: "Backups",    desc: "Snapshots",       href: "/dashboard/reseller/backups",          Icon: IconArchive,  color: "#DC2626" },
  ],
};

export function RoleDashboard({ expectedRole, title, modules }: RoleDashboardProps) {
  const router = useRouter();
  const [user, setUser] = useState<StoredUser | null>(null);
  const [recentJobs, setRecentJobs] = useState<Job[]>([]);
  const [jobsLoading, setJobsLoading] = useState(true);

  const apiBase = useMemo(() => process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api", []);

  useEffect(() => {
    const token = localStorage.getItem("eupanel_token");
    const raw = localStorage.getItem("eupanel_user");
    if (!token || !raw) { router.replace("/"); return; }

    const parsed = JSON.parse(raw) as StoredUser;
    const role = parsed.role?.toLowerCase();
    if (role !== expectedRole) {
      router.replace(
        role === "admin" ? "/dashboard/admin" :
        role === "reseller" ? "/dashboard/reseller" : "/dashboard"
      );
      return;
    }
    setUser(parsed);

    fetch(`${apiBase}/jobs`, { headers: { Authorization: `Bearer ${token}` } })
      .then((r) => r.json())
      .then((d: { data?: Job[] }) => setRecentJobs((d.data ?? []).slice(0, 8)))
      .catch(() => {})
      .finally(() => setJobsLoading(false));
  }, [apiBase, expectedRole, router]);

  function logout() {
    localStorage.removeItem("eupanel_token");
    localStorage.removeItem("eupanel_user");
    router.replace("/");
  }

  const actions = QUICK_ACTIONS[expectedRole] ?? [];
  const displayName = user?.name ?? expectedRole;
  const firstName = displayName.split(" ")[0];
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long", month: "long", day: "numeric",
  });

  return (
    <div className="ep-shell">
      <DashboardSidebar role={expectedRole} onLogout={logout} />

      <main className="ep-main">
        {/* Topbar */}
        <div className="ep-topbar">
          <div className="ep-topbar-breadcrumb">
            <strong>{title}</strong>
          </div>
          <div className="ep-topbar-right">
            <span className="ep-badge ep-badge-success">
              <span
                className="ep-badge-dot ep-dot-pulse"
                style={{ background: "var(--ep-success)" }}
              />
              All systems operational
            </span>
          </div>
        </div>

        <div className="ep-content">

          {/* Welcome hero */}
          <div className="ep-dashboard-hero">
            <h1 className="ep-dashboard-greeting">
              {greeting()}, {firstName}
            </h1>
            <p className="ep-dashboard-date">
              <span>{today}</span>
              <span className="ep-dashboard-date-sep">·</span>
              <span className="ep-dashboard-module-count">
                {modules.length} modules available
              </span>
            </p>
          </div>

          {/* Quick Access */}
          <section>
            <p className="ep-section-label">Quick Access</p>
            <div className="ep-action-grid">
              {actions.map((a) => (
                <Link key={a.href} href={a.href} className="ep-action-card">
                  <div
                    className="ep-action-icon"
                    style={{
                      background: `${a.color}18`,
                      border: `1px solid ${a.color}2a`,
                      color: a.color,
                    }}
                  >
                    <a.Icon size={16} />
                  </div>
                  <div>
                    <div className="ep-action-label">{a.label}</div>
                    <div className="ep-action-desc">{a.desc}</div>
                  </div>
                </Link>
              ))}
            </div>
          </section>

          {/* Recent Jobs */}
          <section>
            <div className="ep-card">
              <div className="ep-card-header">
                <span className="ep-card-title ep-card-title-icon">
                  <span style={{ color: "var(--ep-text-muted)", display: "flex" }}>
                    <IconQueue size={15} />
                  </span>
                  Recent Jobs
                </span>
                {expectedRole === "admin" && (
                  <Link href="/dashboard/admin/jobs" className="ep-btn ep-btn-ghost ep-btn-sm">
                    View all
                  </Link>
                )}
              </div>

              <div className="ep-table-wrap">
                {jobsLoading ? (
                  <div className="ep-skeleton-list">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="ep-skeleton ep-skeleton-row" />
                    ))}
                  </div>
                ) : recentJobs.length === 0 ? (
                  <div className="ep-empty">
                    <div className="ep-empty-icon"><IconCheck size={18} /></div>
                    <div className="ep-empty-title">No jobs yet</div>
                    <div className="ep-empty-desc">
                      Jobs appear here when sites, databases, or SSL certs are provisioned.
                    </div>
                  </div>
                ) : (
                  <table className="ep-table">
                    <thead>
                      <tr>
                        <th>Type</th>
                        <th>Target</th>
                        <th>Status</th>
                        <th>Job ID</th>
                      </tr>
                    </thead>
                    <tbody>
                      {recentJobs.map((job) => (
                        <tr key={job.id}>
                          <td><span className="ep-text-mono">{job.type}</span></td>
                          <td className="ep-table-muted">{job.targetType ?? "—"}</td>
                          <td><StatusBadge status={job.status} /></td>
                          <td>
                            <span className="ep-text-mono ep-text-faint">
                              {job.id.slice(0, 8)}…
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </section>

          {/* Modules */}
          <section>
            <p className="ep-section-label">All Modules</p>
            <div className="ep-module-grid">
              {modules.map((mod) => (
                <span key={mod} className="ep-module-chip">
                  <span className="ep-module-dot" />
                  {mod}
                </span>
              ))}
            </div>
          </section>

        </div>
      </main>
    </div>
  );
}
