import { ActionIcon } from "@/components/websites-domains/action-icon";
import { ActionIconName } from "@/components/websites-domains/types";

export function ActionButton({ label, icon }: { label: string; icon: ActionIconName }) {
  return (
    <button
      className="ep-btn ep-btn-ghost ep-btn-sm"
      style={{ justifyContent: "flex-start", color: "var(--ep-text-muted)" }}
    >
      <ActionIcon name={icon} />
      <span>{label}</span>
    </button>
  );
}
