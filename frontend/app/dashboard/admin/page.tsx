import { RoleDashboard } from "@/components/role-dashboard";

export default function AdminDashboardPage() {
  return (
    <RoleDashboard
      expectedRole="admin"
      title="Administrator Control Center"
      modules={[
        "Servers",
        "Sites",
        "Runtimes",
        "Databases",
        "DNS",
        "SSL",
        "Backups",
        "Jobs",
      ]}
    />
  );
}
