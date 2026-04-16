"use client";

import { useEffect, useState } from "react";

// ── Types ─────────────────────────────────────────────────────────────────────

interface Plan {
  id: string;
  name: string;
  description?: string;
  disk_limit: number;
  bandwidth_limit: number;
  ftp_accounts_limit: number;
  database_limit: number;
  domain_limit: number;
  price?: number;
  status: string;
}

interface Subscription {
  id: string;
  plan_id: string;
  system_username: string;
  ftp_username: string;
  home_directory: string;
  status: "pending" | "active" | "suspended" | "cancelled";
  provisioning_status: "pending" | "provisioning" | "success" | "failed" | "deprovisioned";
  provisioning_log?: string;
  created_at: string;
}

const STATUS_MAP: Record<string, { label: string; cls: string }> = {
  active: { label: "Active", cls: "ep-badge-success" },
  pending: { label: "Pending", cls: "ep-badge-warning" },
  suspended: { label: "Suspended", cls: "ep-badge-warning" },
  cancelled: { label: "Cancelled", cls: "ep-badge-neutral" },
};

const PROV_MAP: Record<string, { label: string; cls: string }> = {
  success: { label: "Provisioned", cls: "ep-badge-success" },
  provisioning: { label: "Provisioning…", cls: "ep-badge-warning" },
  pending: { label: "Queued", cls: "ep-badge-neutral" },
  failed: { label: "Failed", cls: "ep-badge-danger" },
  deprovisioned: { label: "Deprovisioned", cls: "ep-badge-neutral" },
};

// ── Component ─────────────────────────────────────────────────────────────────

export function SubscriptionsScreen() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);
  const [expandedLog, setExpandedLog] = useState<string | null>(null);
  const [cancelConfirm, setCancelConfirm] = useState<string | null>(null);

  const API = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  function authHeaders() {
    const token = localStorage.getItem("eupanel_token");
    return { "Content-Type": "application/json", Authorization: `Bearer ${token}` };
  }

  async function fetchAll() {
    setLoading(true);
    try {
      const [subsRes, plansRes] = await Promise.all([
        fetch(`${API}/subscriptions`, { headers: authHeaders() }),
        fetch(`${API}/plans`, { headers: authHeaders() }),
      ]);
      const subsData = await subsRes.json();
      const plansData = await plansRes.json();
      setSubs(subsData.data ?? []);
      setPlans((plansData.data ?? []).filter((p: Plan) => p.status === "active"));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { fetchAll(); }, []);

  async function createSubscription() {
    if (!selectedPlan) return;
    setCreating(true);
    setCreateError(null);
    try {
      const r = await fetch(`${API}/subscriptions`, {
        method: "POST",
        headers: authHeaders(),
        body: JSON.stringify({ plan_id: selectedPlan }),
      });
      const d = await r.json();
      if (!r.ok && r.status !== 201 && r.status !== 202) {
        setCreateError(d.message ?? JSON.stringify(d.errors ?? d));
        return;
      }
      setShowCreate(false);
      setSelectedPlan(null);
      fetchAll();
    } finally {
      setCreating(false);
    }
  }

  async function cancelSubscription(id: string) {
    const r = await fetch(`${API}/subscriptions/${id}`, {
      method: "DELETE",
      headers: authHeaders(),
    });
    if (r.ok) {
      setCancelConfirm(null);
      fetchAll();
    }
  }

  const selectedPlanData = plans.find((p) => p.id === selectedPlan);

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div className="ep-content">
      {/* Header */}
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "2rem", gap: "1rem" }}>
        <div>
          <h1 style={{ fontSize: "1.375rem", fontWeight: 700, letterSpacing: "-0.02em", margin: 0 }}>
            My Subscriptions
          </h1>
          <p style={{ margin: "0.35rem 0 0", color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
            Each subscription provisions a dedicated hosting account on the server.
          </p>
        </div>
        {plans.length > 0 && (
          <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={() => { setShowCreate(true); setCreateError(null); }}>
            + New Subscription
          </button>
        )}
      </div>

      {/* Subscriptions */}
      {loading ? (
        <div className="ep-card ep-skeleton-list">
          {[...Array(3)].map((_, i) => <div key={i} className="ep-skeleton ep-skeleton-row" />)}
        </div>
      ) : subs.length === 0 ? (
        <EmptyState plans={plans} onSubscribe={() => { setShowCreate(true); setCreateError(null); }} />
      ) : (
        <div style={{ display: "grid", gap: "1rem" }}>
          {subs.map((sub) => {
            const plan = plans.find((p) => p.id === sub.plan_id);
            const statusInfo = STATUS_MAP[sub.status] ?? { label: sub.status, cls: "ep-badge-neutral" };
            const provInfo = PROV_MAP[sub.provisioning_status] ?? { label: sub.provisioning_status, cls: "ep-badge-neutral" };
            return (
              <div key={sub.id} className="ep-card">
                <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: "1rem" }}>
                  <div>
                    <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", flexWrap: "wrap" }}>
                      <span style={{ fontWeight: 600, fontSize: "0.9375rem" }}>
                        {plan?.name ?? "Unknown Plan"}
                      </span>
                      <span className={`ep-badge ${statusInfo.cls}`}>{statusInfo.label}</span>
                      <span className={`ep-badge ${provInfo.cls}`}>{provInfo.label}</span>
                    </div>
                    <p style={{ margin: "0.4rem 0 0", fontSize: "0.84rem", color: "var(--ep-text-muted)" }}>
                      Created {new Date(sub.created_at).toLocaleDateString()}
                    </p>
                  </div>

                  <div style={{ display: "flex", gap: "0.5rem", flexShrink: 0 }}>
                    {sub.provisioning_status === "failed" && (
                      <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setExpandedLog(expandedLog === sub.id ? null : sub.id)}>
                        View Log
                      </button>
                    )}
                    {sub.status !== "cancelled" && (
                      <button
                        className="ep-btn ep-btn-ghost ep-btn-xs"
                        style={{ color: "var(--ep-danger)" }}
                        onClick={() => setCancelConfirm(sub.id)}
                      >
                        Cancel
                      </button>
                    )}
                  </div>
                </div>

                {/* Server details */}
                {sub.provisioning_status === "success" && (
                  <div style={{ marginTop: "1rem", display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))", gap: "0.75rem" }}>
                    <InfoCard label="System User" value={sub.system_username} mono />
                    <InfoCard label="FTP User" value={sub.ftp_username} mono />
                    <InfoCard label="Home Directory" value={sub.home_directory} mono />
                    {plan && <InfoCard label="Disk Limit" value={fmtMB(plan.disk_limit)} />}
                    {plan && <InfoCard label="Bandwidth" value={fmtMB(plan.bandwidth_limit)} />}
                    {plan && <InfoCard label="Domains" value={String(plan.domain_limit)} />}
                  </div>
                )}

                {/* Provisioning log */}
                {expandedLog === sub.id && sub.provisioning_log && (
                  <pre style={{
                    marginTop: "1rem",
                    padding: "0.875rem",
                    background: "var(--ep-bg)",
                    borderRadius: "var(--ep-r-md)",
                    fontSize: "0.78rem",
                    color: "var(--ep-danger)",
                    overflowX: "auto",
                    whiteSpace: "pre-wrap",
                    border: "1px solid var(--ep-border)",
                  }}>
                    {sub.provisioning_log}
                  </pre>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Create Subscription Modal */}
      {showCreate && (
        <div className="ep-modal-overlay" onClick={() => setShowCreate(false)}>
          <div className="ep-modal" style={{ width: "min(640px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>New Subscription</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setShowCreate(false)}>✕</button>
            </div>

            <div className="ep-modal-body">
              {createError && (
                <div style={{ padding: "0.6rem 0.75rem", marginBottom: "1rem", background: "color-mix(in srgb, var(--ep-danger) 10%, transparent)", border: "1px solid color-mix(in srgb, var(--ep-danger) 25%, transparent)", borderRadius: "var(--ep-r-md)", fontSize: "0.84rem", color: "var(--ep-danger)" }}>
                  {createError}
                </div>
              )}

              <p style={{ marginBottom: "1rem", fontSize: "0.875rem", color: "var(--ep-text-muted)" }}>
                Select a plan. A Linux system user, home directory, and FTP account will be created automatically.
              </p>

              <div style={{ display: "grid", gap: "0.75rem" }}>
                {plans.map((plan) => (
                  <label key={plan.id} style={{
                    display: "flex",
                    alignItems: "flex-start",
                    gap: "0.875rem",
                    padding: "1rem 1.125rem",
                    border: `1px solid ${selectedPlan === plan.id ? "var(--ep-accent)" : "var(--ep-border)"}`,
                    borderRadius: "var(--ep-r-lg)",
                    cursor: "pointer",
                    background: selectedPlan === plan.id ? "color-mix(in srgb, var(--ep-accent) 6%, var(--ep-surface))" : "var(--ep-surface)",
                    transition: "border-color 0.15s, background 0.15s",
                  }}>
                    <input
                      type="radio"
                      name="plan"
                      value={plan.id}
                      checked={selectedPlan === plan.id}
                      onChange={() => setSelectedPlan(plan.id)}
                      style={{ marginTop: "0.15rem", accentColor: "var(--ep-accent)" }}
                    />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", justifyContent: "space-between" }}>
                        <span style={{ fontWeight: 600, fontSize: "0.9375rem" }}>{plan.name}</span>
                        {plan.price != null && (
                          <span style={{ fontSize: "0.875rem", fontWeight: 600, color: "var(--ep-accent)" }}>
                            ${Number(plan.price).toFixed(2)}/mo
                          </span>
                        )}
                      </div>
                      {plan.description && (
                        <p style={{ margin: "0.2rem 0 0.5rem", fontSize: "0.8125rem", color: "var(--ep-text-muted)" }}>{plan.description}</p>
                      )}
                      <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap", marginTop: "0.4rem" }}>
                        <Chip label={`${fmtMB(plan.disk_limit)} Disk`} />
                        <Chip label={`${fmtMB(plan.bandwidth_limit)} BW`} />
                        <Chip label={`${plan.domain_limit} Domain${plan.domain_limit !== 1 ? "s" : ""}`} />
                        <Chip label={`${plan.database_limit} DB${plan.database_limit !== 1 ? "s" : ""}`} />
                        <Chip label={`${plan.ftp_accounts_limit} FTP`} />
                      </div>
                    </div>
                  </label>
                ))}
              </div>

              {/* Provisioning explanation */}
              {selectedPlan && (
                <div style={{ marginTop: "1.25rem", padding: "0.875rem 1rem", background: "var(--ep-bg)", border: "1px solid var(--ep-border)", borderRadius: "var(--ep-r-md)", fontSize: "0.8125rem", color: "var(--ep-text-muted)" }}>
                  <strong style={{ color: "var(--ep-text)", display: "block", marginBottom: "0.35rem" }}>What happens next</strong>
                  A Linux system user will be created on the server, a home directory at <code style={{ fontFamily: "var(--font-ibm-plex-mono)", fontSize: "0.8rem" }}>/home/eu…/</code> will be set up with a <code style={{ fontFamily: "var(--font-ibm-plex-mono)", fontSize: "0.8rem" }}>public_html</code> folder, and an FTP account will be provisioned. This takes a few seconds.
                </div>
              )}
            </div>

            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setShowCreate(false)}>Cancel</button>
              <button
                className="ep-btn ep-btn-primary ep-btn-sm"
                onClick={createSubscription}
                disabled={!selectedPlan || creating}
              >
                {creating ? "Provisioning…" : "Create Subscription"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Cancel Confirm */}
      {cancelConfirm && (
        <div className="ep-modal-overlay" onClick={() => setCancelConfirm(null)}>
          <div className="ep-modal" style={{ width: "min(420px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>Cancel Subscription</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setCancelConfirm(null)}>✕</button>
            </div>
            <div className="ep-modal-body">
              <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
                This will cancel the subscription and remove the system user and FTP account from the server. This cannot be undone.
              </p>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setCancelConfirm(null)}>Keep It</button>
              <button className="ep-btn ep-btn-sm" style={{ background: "var(--ep-danger)", color: "#fff" }} onClick={() => cancelSubscription(cancelConfirm)}>
                Cancel Subscription
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────────

function EmptyState({ plans, onSubscribe }: { plans: Plan[]; onSubscribe: () => void }) {
  return (
    <div className="ep-card" style={{ padding: "3rem 2rem", textAlign: "center" }}>
      <div style={{ fontSize: "2rem", marginBottom: "0.75rem" }}>🚀</div>
      <h3 style={{ fontWeight: 600, margin: "0 0 0.5rem" }}>No subscriptions yet</h3>
      <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem", margin: "0 0 1.5rem" }}>
        Subscribe to a hosting plan to get your server account provisioned automatically.
      </p>
      {plans.length > 0 ? (
        <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={onSubscribe}>
          Choose a Plan
        </button>
      ) : (
        <p style={{ color: "var(--ep-text-faint)", fontSize: "0.8125rem" }}>No plans are available yet. Ask your admin to create one.</p>
      )}
    </div>
  );
}

function InfoCard({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div style={{ padding: "0.75rem", background: "var(--ep-bg)", borderRadius: "var(--ep-r-md)", border: "1px solid var(--ep-border)" }}>
      <div style={{ fontSize: "0.72rem", fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--ep-text-muted)", marginBottom: "0.25rem" }}>
        {label}
      </div>
      <div style={{ fontSize: "0.84rem", fontFamily: mono ? "var(--font-ibm-plex-mono)" : undefined, fontWeight: mono ? 400 : 500 }}>
        {value}
      </div>
    </div>
  );
}

function Chip({ label }: { label: string }) {
  return (
    <span style={{ fontSize: "0.75rem", padding: "0.15rem 0.5rem", background: "var(--ep-bg)", border: "1px solid var(--ep-border)", borderRadius: "999px", color: "var(--ep-text-muted)" }}>
      {label}
    </span>
  );
}

function fmtMB(mb: number): string {
  if (mb >= 1024 * 1024) return `${(mb / (1024 * 1024)).toFixed(0)} TB`;
  if (mb >= 1024) return `${(mb / 1024).toFixed(0)} GB`;
  return `${mb} MB`;
}
