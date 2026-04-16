import { RoleDashboard } from "@/components/role-dashboard";

export default function CustomerDashboardPage() {
  return (
    <RoleDashboard
      expectedRole="customer"
      title="Customer Hosting Dashboard"
      modules={["Sites", "Databases", "DNS", "SSL", "Backups", "Jobs"]}
    />
  );
}
