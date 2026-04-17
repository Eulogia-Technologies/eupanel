"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { DashboardSidebar } from "@/components/dashboard-sidebar";
import { SystemUpdateButton } from "@/components/system-update-modal";
import { Menu } from "lucide-react";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("eupanel_token");
    const raw = localStorage.getItem("eupanel_user");
    if (!token || !raw) { router.replace("/"); return; }
    const user = JSON.parse(raw) as { role?: string };
    if (user.role?.toLowerCase() !== "admin") {
      router.replace(user.role?.toLowerCase() === "customer" ? "/dashboard" : "/");
      return;
    }
    setReady(true);
  }, [router]);

  function logout() {
    localStorage.removeItem("eupanel_token");
    localStorage.removeItem("eupanel_user");
    router.replace("/");
  }

  if (!ready) return <div className="ep-shell ep-shell-loading" />;

  return (
    <div className="ep-shell">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="ep-sidebar-overlay"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <DashboardSidebar
        role="admin"
        onLogout={logout}
        open={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />

      <main className="ep-main">
        {/* Admin topbar */}
        <div className="ep-topbar" style={{ justifyContent: "space-between" }}>
          {/* Hamburger – mobile only, hidden via CSS on desktop */}
          <button
            className="ep-hamburger"
            onClick={() => setSidebarOpen(true)}
            aria-label="Open menu"
          >
            <Menu size={20} />
          </button>
          <SystemUpdateButton />
        </div>
        {children}
      </main>
    </div>
  );
}
