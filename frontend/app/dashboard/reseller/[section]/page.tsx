import { RoleSectionScreen } from "@/components/role-section-screen";
import { getSectionTitle } from "@/lib/dashboard-nav";

export default async function ResellerSectionPage({
  params,
}: {
  params: Promise<{ section: string }>;
}) {
  const { section } = await params;
  return (
    <RoleSectionScreen
      expectedRole="reseller"
      sectionTitle={getSectionTitle("reseller", section)}
    />
  );
}
