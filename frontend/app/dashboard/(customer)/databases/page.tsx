import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function CustomerDatabasesPage() {
  return (
    <CustomerResourceScreen
      title="Databases"
      endpoint="/databases"
      columns={[
        { key: "name", label: "Database" },
        { key: "engine", label: "Engine" },
        { key: "username", label: "User" },
        { key: "status", label: "Status" },
      ]}
      createFields={[
        { key: "serverId", label: "Server ID", placeholder: "local-server-1" },
        { key: "engine", label: "Engine", placeholder: "postgres or mysql" },
        { key: "name", label: "Database Name", placeholder: "app_db" },
        { key: "username", label: "Username", placeholder: "app_user" },
        { key: "password", label: "Password", placeholder: "secure-password" },
      ]}
    />
  );
}

