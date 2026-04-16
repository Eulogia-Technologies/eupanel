import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function ResellerDnsSettingsPage() {
  return (
    <CustomerResourceScreen
      expectedRole="reseller"
      title="DNS Settings"
      endpoint="/dns/zones"
      columns={[
        { key: "domain", label: "Domain" },
        { key: "status", label: "Status" },
        { key: "id", label: "Zone ID" },
      ]}
      createFields={[{ key: "domain", label: "Domain", placeholder: "example.com" }]}
    />
  );
}

