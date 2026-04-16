import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function AdminCustomersPage() {
  return (
    <CustomerResourceScreen
      title="Customers"
      endpoint="/users"
      expectedRole="admin"
      columns={[
        { key: "name", label: "Name" },
        { key: "email", label: "Email" },
        { key: "role", label: "Role" },
      ]}
      createFields={[
        { key: "name", label: "Full Name", placeholder: "Jane Doe" },
        { key: "email", label: "Email", placeholder: "jane@example.com" },
        { key: "password", label: "Password", placeholder: "min 8 characters" },
        { key: "role", label: "Role", placeholder: "customer / reseller / admin" },
      ]}
    />
  );
}
