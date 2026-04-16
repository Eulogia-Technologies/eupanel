import { RoleDashboard } from "@/components/role-dashboard";

export default function ResellerDashboardPage() {
  return (
    <RoleDashboard
      expectedRole="reseller"
      title="Reseller Management Dashboard"
      modules={["Customers", "Sites", "Databases", "DNS", "SSL", "Backups", "Jobs"]}
    />
  );
}
