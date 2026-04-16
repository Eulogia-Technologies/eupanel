import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function ResellerBackupsPage() {
  return (
    <CustomerResourceScreen
      title="Backups"
      endpoint="/backups"
      expectedRole="reseller"
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
