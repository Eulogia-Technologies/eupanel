import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function CustomerBackupsPage() {
  return (
    <CustomerResourceScreen
      title="Backups"
      endpoint="/backups"
      columns={[
        { key: "siteId", label: "Site ID" },
        { key: "status", label: "Status" },
        { key: "filePath", label: "File" },
        { key: "fileSizeBytes", label: "Size (bytes)" },
      ]}
      createFields={[
        { key: "siteId", label: "Site ID", placeholder: "site-id" },
      ]}
    />
  );
}
