import { ManageitScreen } from "@/components/manageit-screen";

export default async function ManageitPage({
  params,
}: {
  params: Promise<{ moduleId: string }>;
}) {
  const { moduleId } = await params;
  return <ManageitScreen moduleId={moduleId} />;
}
