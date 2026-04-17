"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { DashboardSidebar } from "@/components/dashboard-sidebar";

export default function CustomerLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("eupanel_token");
    const raw = localStorage.getItem("eupanel_user");
    if (!token || !raw) { router.replace("/"); return; }
    const user = JSON.parse(raw) as { role?: string };
    const role = user.role?.toLowerCase();
    if (role !== "customer" && role !== "admin") {
      router.replace("/");
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
      <DashboardSidebar role="customer" onLogout={logout} />
      <main className="ep-main">
        {children}
      </main>
    </div>
  );
}
