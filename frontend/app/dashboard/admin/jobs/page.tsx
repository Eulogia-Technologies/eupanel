import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function AdminJobsPage() {
  return (
    <CustomerResourceScreen
      title="Jobs"
      endpoint="/jobs"
      expectedRole="admin"
      columns={[
        { key: "type", label: "Type" },
        { key: "status", label: "Status" },
        { key: "targetType", label: "Target" },
        { key: "targetId", label: "Target ID" },
      ]}
    />
  );
}
