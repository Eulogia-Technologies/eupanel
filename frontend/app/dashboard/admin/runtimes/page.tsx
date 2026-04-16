import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function AdminRuntimesPage() {
  return (
    <CustomerResourceScreen
      title="Runtimes"
      endpoint="/runtimes"
      expectedRole="admin"
      columns={[
        { key: "siteId", label: "Site ID" },
        { key: "runtime", label: "Runtime" },
        { key: "version", label: "Version" },
        { key: "serviceName", label: "Service" },
        { key: "port", label: "Port" },
      ]}
      createFields={[
        { key: "siteId", label: "Site ID", placeholder: "site-id" },
        { key: "runtime", label: "Runtime", placeholder: "php / nodejs / dart / python" },
        { key: "version", label: "Version", placeholder: "8.3" },
        { key: "startCommand", label: "Start Command", placeholder: "php-fpm" },
        { key: "port", label: "Port", placeholder: "9000" },
        { key: "serviceName", label: "Service Name", placeholder: "php-fpm" },
      ]}
    />
  );
}
