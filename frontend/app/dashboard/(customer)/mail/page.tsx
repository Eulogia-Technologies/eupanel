import { CustomerResourceScreen } from "@/components/customer-resource-screen";

export default function CustomerMailPage() {
  return (
    <CustomerResourceScreen
      title="Mail Accounts"
      endpoint="/mail"
      columns={[
        { key: "email", label: "Email" },
        { key: "domain", label: "Domain" },
        { key: "status", label: "Status" },
        { key: "forwardTo", label: "Forward To" },
      ]}
      createFields={[
        { key: "domain", label: "Domain", placeholder: "example.com" },
        { key: "email", label: "Email", placeholder: "hello@example.com" },
        { key: "password", label: "Password", placeholder: "mail-password" },
        { key: "forwardTo", label: "Forward To", placeholder: "optional@forward.com" },
      ]}
    />
  );
}

