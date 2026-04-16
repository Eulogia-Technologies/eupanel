"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { DashboardSidebar } from "@/components/dashboard-sidebar";
import { IconChevronRight } from "@/components/ui/icons";

type RoleSectionScreenProps = {
  expectedRole: "admin" | "customer" | "reseller";
  sectionTitle: string;
};

export function RoleSectionScreen({ expectedRole, sectionTitle }: RoleSectionScreenProps) {
  const router = useRouter();

  useEffect(() => {
    const token = localStorage.getItem("eupanel_token");
    const raw   = localStorage.getItem("eupanel_user");
    if (!token || !raw) { router.replace("/"); return; }
    const role = (JSON.parse(raw) as { role?: string }).role?.toLowerCase();
    if (role !== expectedRole) {
      router.replace(role === "admin" ? "/dashboard/admin" : role === "reseller" ? "/dashboard/reseller" : "/dashboard");
    }
  }, [expectedRole, router]);

  function logout() {
    localStorage.removeItem("eupanel_token");
    localStorage.removeItem("eupanel_user");
    router.replace("/");
  }

  return (
    <div className="ep-shell">
      <DashboardSidebar role={expectedRole} onLogout={logout} />

      <main className="ep-main">
        <div className="ep-topbar">
          <div className="ep-topbar-breadcrumb">
            <span style={{ color: "var(--ep-text-faint)" }}>Dashboard</span>
            <span style={{ margin: "0 0.35rem", color: "var(--ep-text-faint)" }}>/</span>
            <strong>{sectionTitle}</strong>
          </div>
        </div>

        <div className="ep-content">
          <div>
            <h1 style={{ fontSize: "1.375rem", fontWeight: 700, letterSpacing: "-0.02em" }}>
              {sectionTitle}
            </h1>
            <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)", marginTop: "0.25rem" }}>
              {expectedRole} panel
            </p>
          </div>

          <div
            className="ep-card"
            style={{
              padding: "3rem 2rem",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              textAlign: "center",
              gap: "1rem",
            }}
          >
            <div
              style={{
                width: "3.5rem",
                height: "3.5rem",
                borderRadius: "var(--ep-r-lg)",
                background: "var(--ep-accent-subtle)",
                border: "1px solid rgba(13,153,112,0.2)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "var(--ep-accent)",
              }}
            >
              <IconChevronRight size={22} />
            </div>
            <div>
              <h2 style={{ fontWeight: 600, fontSize: "1rem" }}>{sectionTitle}</h2>
              <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)", marginTop: "0.35rem", maxWidth: "36ch" }}>
                This section is connected and will be populated once the module is implemented.
              </p>
            </div>
            <span className="ep-badge ep-badge-warning">Coming soon</span>
          </div>
        </div>
      </main>
    </div>
  );
}
