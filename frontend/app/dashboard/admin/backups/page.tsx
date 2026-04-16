import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function AdminBackupsPage() {
  return (
    <CustomerResourceScreen
      title="Backups"
      endpoint="/backups"
      expectedRole="admin"
      columns={[
        { key: "siteId", label: "Site ID" },
        { key: "status", label: "Status" },
        { key: "filePath", label: "File Path" },
        { key: "fileSizeBytes", label: "Size (bytes)" },
      ]}
      createFields={[
        { key: "siteId", label: "Site ID", placeholder: "site-id" },
      ]}
    />
  );
}
