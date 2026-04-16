import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function AdminServersPage() {
  return (
    <CustomerResourceScreen
      title="Servers"
      endpoint="/servers"
      expectedRole="admin"
      columns={[
        { key: "name", label: "Name" },
        { key: "host", label: "Host" },
        { key: "port", label: "Port" },
        { key: "status", label: "Status" },
        { key: "agentVersion", label: "Agent Version" },
      ]}
      createFields={[
        { key: "name", label: "Server Name", placeholder: "prod-server-1" },
        { key: "host", label: "IP / Hostname", placeholder: "192.168.1.10" },
        { key: "port", label: "SSH Port", placeholder: "22" },
      ]}
    />
  );
}
