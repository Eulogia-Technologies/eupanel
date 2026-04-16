import { RoleSectionScreen } from "@/components/role-section-screen";
import { getSectionTitle } from "@/lib/dashboard-nav";

export default async function AdminSectionPage({
  params,
}: {
  params: Promise<{ section: string }>;
}) {
  const { section } = await params;
  return <RoleSectionScreen expectedRole="admin" sectionTitle={getSectionTitle("admin", section)} />;
}
