import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function ResellerSslCertificatesPage() {
  return (
    <CustomerResourceScreen
      expectedRole="reseller"
      title="SSL/TLS Certificates"
      endpoint="/ssl/certificates"
      createEndpoint="/ssl/issue"
      columns={[
        { key: "domain", label: "Domain" },
        { key: "provider", label: "Provider" },
        { key: "status", label: "Status" },
        { key: "expiresAt", label: "Expires At" },
      ]}
      createFields={[
        { key: "siteId", label: "Site ID", placeholder: "site-id" },
        { key: "domain", label: "Domain", placeholder: "example.com" },
      ]}
    />
  );
}

