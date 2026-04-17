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
  subdomain_limit: number;
  ram_limit?: number;
  price?: number;
  status: "active" | "inactive";
  created_at: string;
}

type PlanForm = Omit<Plan, "id" | "created_at">;

const EMPTY_FORM: PlanForm = {
  name: "",
  description: "",
  disk_limit: 10240,
  bandwidth_limit: 102400,
  ftp_accounts_limit: 1,
  database_limit: 1,
  domain_limit: 1,
  subdomain_limit: 10,
  ram_limit: undefined,
  price: undefined,
  status: "active",
};

// ── Component ─────────────────────────────────────────────────────────────────

export function PlansScreen() {
  const [plans, setPlans]               = useState<Plan[]>([]);
  const [loading, setLoading]           = useState(true);
  const [showModal, setShowModal]       = useState(false);
  const [editingPlan, setEditingPlan]   = useState<Plan | null>(null);
  const [form, setForm]                 = useState<PlanForm>(EMPTY_FORM);
  const [saving, setSaving]             = useState(false);
  const [error, setError]               = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<Plan | null>(null);

  const API = process.env.NEXT_PUBLIC_FRONTEND_API_BASE ?? "/api";

  function authHeaders() {
    const token = typeof window !== "undefined" ? localStorage.getItem("eupanel_token") : "";
    return { "Content-Type": "application/json", Authorization: `Bearer ${token}` };
  }

  async function fetchPlans() {
    setLoading(true);
    try {
      const r = await fetch(`${API}/plans`, { headers: authHeaders() });
      const d = await r.json();
      setPlans(d.data ?? []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { fetchPlans(); }, []);

  function openCreate() {
    setEditingPlan(null);
    setForm(EMPTY_FORM);
    setError(null);
    setShowModal(true);
  }

  function openEdit(plan: Plan) {
    setEditingPlan(plan);
    setForm({
      name:               plan.name,
      description:        plan.description ?? "",
      disk_limit:         plan.disk_limit,
      bandwidth_limit:    plan.bandwidth_limit,
      ftp_accounts_limit: plan.ftp_accounts_limit,
      database_limit:     plan.database_limit,
      domain_limit:       plan.domain_limit,
      subdomain_limit:    plan.subdomain_limit ?? 10,
      ram_limit:          plan.ram_limit,
      price:              plan.price,
      status:             plan.status,
    });
    setError(null);
    setShowModal(true);
  }

  async function savePlan() {
    setSaving(true);
    setError(null);
    try {
      const url    = editingPlan ? `${API}/plans/${editingPlan.id}` : `${API}/plans`;
      const method = editingPlan ? "PUT" : "POST";
      const r = await fetch(url, {
        method,
        headers: authHeaders(),
        body: JSON.stringify(form),
      });
      const d = await r.json();
      if (!r.ok) {
        setError(d.message ?? JSON.stringify(d.errors ?? d));
        return;
      }
      setShowModal(false);
      fetchPlans();
    } finally {
      setSaving(false);
    }
  }

  async function deletePlan(plan: Plan) {
    const r = await fetch(`${API}/plans/${plan.id}`, {
      method: "DELETE",
      headers: authHeaders(),
    });
    if (r.ok) {
      setDeleteConfirm(null);
      fetchPlans();
    }
  }

  function field(key: keyof PlanForm, value: unknown) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div className="ep-content">

      {/* Header */}
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: "2rem", gap: "1rem" }}>
        <div>
          <h1 style={{ fontSize: "1.375rem", fontWeight: 700, letterSpacing: "-0.02em", margin: 0 }}>
            Service Plans
          </h1>
          <p style={{ margin: "0.35rem 0 0", color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
            Define resource limits that customers subscribe to.
          </p>
        </div>
        <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={openCreate}>
          + New Plan
        </button>
      </div>

      {/* Plans grid */}
      {loading ? (
        <div className="ep-card" style={{ padding: 0 }}>
          <div className="ep-skeleton-list">
            {[...Array(3)].map((_, i) => <div key={i} className="ep-skeleton ep-skeleton-row" />)}
          </div>
        </div>
      ) : plans.length === 0 ? (
        <div className="ep-card" style={{ padding: "4rem 2rem", textAlign: "center" }}>
          <p style={{ fontSize: "0.875rem", color: "var(--ep-text-muted)", marginBottom: "1rem" }}>
            No plans yet. Create your first hosting plan.
          </p>
          <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={openCreate}>
            Create Plan
          </button>
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: "1rem" }}>
          {plans.map((plan) => (
            <PlanCard
              key={plan.id}
              plan={plan}
              onEdit={() => openEdit(plan)}
              onDelete={() => setDeleteConfirm(plan)}
            />
          ))}
        </div>
      )}

      {/* Create / Edit Modal */}
      {showModal && (
        <div className="ep-modal-overlay" onClick={() => setShowModal(false)}>
          <div
            className="ep-modal"
            style={{ width: "min(640px, 95vw)", maxHeight: "90vh", overflowY: "auto" }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="ep-modal-header">
              <h2>{editingPlan ? "Edit Plan" : "New Hosting Plan"}</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div className="ep-modal-body" style={{ display: "grid", gap: "1.25rem" }}>
              {error && (
                <div style={{ background: "var(--ep-danger-bg, #fff0f0)", border: "1px solid var(--ep-danger)", color: "var(--ep-danger)", borderRadius: "var(--ep-r-md)", padding: "0.6rem 0.75rem", fontSize: "0.84rem" }}>
                  {error}
                </div>
              )}

              {/* Basic info */}
              <fieldset style={{ border: "none", padding: 0, margin: 0 }}>
                <legend style={{ fontSize: "0.75rem", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", color: "var(--ep-text-muted)", marginBottom: "0.75rem" }}>
                  Basic Info
                </legend>
                <div style={{ display: "grid", gap: "0.75rem" }}>
                  <div className="ep-form-group">
                    <label className="ep-label">Plan Name *</label>
                    <input
                      className="ep-input"
                      value={form.name}
                      onChange={(e) => field("name", e.target.value)}
                      placeholder="e.g. Starter, Pro, Business"
                    />
                  </div>
                  <div className="ep-form-group">
                    <label className="ep-label">Description</label>
                    <input
                      className="ep-input"
                      value={form.description}
                      onChange={(e) => field("description", e.target.value)}
                      placeholder="Short description shown to customers"
                    />
                  </div>
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
                    <div className="ep-form-group">
                      <label className="ep-label">Price / month (USD)</label>
                      <input
                        className="ep-input"
                        type="number"
                        step="0.01"
                        min="0"
                        value={form.price ?? ""}
                        onChange={(e) => field("price", e.target.value ? +e.target.value : undefined)}
                        placeholder="Free"
                      />
                    </div>
                    <div className="ep-form-group">
                      <label className="ep-label">Status</label>
                      <select className="ep-input" value={form.status} onChange={(e) => field("status", e.target.value)}>
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                  </div>
                </div>
              </fieldset>

              {/* Storage & Bandwidth */}
              <fieldset style={{ border: "none", padding: 0, margin: 0 }}>
                <legend style={{ fontSize: "0.75rem", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", color: "var(--ep-text-muted)", marginBottom: "0.75rem" }}>
                  Storage &amp; Bandwidth
                </legend>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
                  <div className="ep-form-group">
                    <label className="ep-label">Disk Limit (MB)</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="1"
                      value={form.disk_limit}
                      onChange={(e) => field("disk_limit", +e.target.value)}
                    />
                    <span style={{ fontSize: "0.75rem", color: "var(--ep-text-faint)" }}>{fmtMB(form.disk_limit)}</span>
                  </div>
                  <div className="ep-form-group">
                    <label className="ep-label">Bandwidth / month (MB)</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="1"
                      value={form.bandwidth_limit}
                      onChange={(e) => field("bandwidth_limit", +e.target.value)}
                    />
                    <span style={{ fontSize: "0.75rem", color: "var(--ep-text-faint)" }}>{fmtMB(form.bandwidth_limit)}</span>
                  </div>
                  <div className="ep-form-group">
                    <label className="ep-label">RAM Limit (MB)</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="0"
                      value={form.ram_limit ?? ""}
                      onChange={(e) => field("ram_limit", e.target.value ? +e.target.value : undefined)}
                      placeholder="Unlimited"
                    />
                    {form.ram_limit && (
                      <span style={{ fontSize: "0.75rem", color: "var(--ep-text-faint)" }}>{fmtMB(form.ram_limit)}</span>
                    )}
                  </div>
                </div>
              </fieldset>

              {/* Hosting Limits */}
              <fieldset style={{ border: "none", padding: 0, margin: 0 }}>
                <legend style={{ fontSize: "0.75rem", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", color: "var(--ep-text-muted)", marginBottom: "0.75rem" }}>
                  Hosting Limits
                </legend>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
                  <div className="ep-form-group">
                    <label className="ep-label">Domains</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="0"
                      value={form.domain_limit}
                      onChange={(e) => field("domain_limit", +e.target.value)}
                    />
                  </div>
                  <div className="ep-form-group">
                    <label className="ep-label">Subdomains</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="0"
                      value={form.subdomain_limit}
                      onChange={(e) => field("subdomain_limit", +e.target.value)}
                    />
                  </div>
                  <div className="ep-form-group">
                    <label className="ep-label">Databases</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="0"
                      value={form.database_limit}
                      onChange={(e) => field("database_limit", +e.target.value)}
                    />
                  </div>
                  <div className="ep-form-group">
                    <label className="ep-label">FTP Accounts</label>
                    <input
                      className="ep-input"
                      type="number"
                      min="0"
                      value={form.ftp_accounts_limit}
                      onChange={(e) => field("ftp_accounts_limit", +e.target.value)}
                    />
                  </div>
                </div>
              </fieldset>
            </div>

            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setShowModal(false)}>
                Cancel
              </button>
              <button className="ep-btn ep-btn-primary ep-btn-sm" onClick={savePlan} disabled={saving}>
                {saving ? "Saving…" : editingPlan ? "Save Changes" : "Create Plan"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete confirm */}
      {deleteConfirm && (
        <div className="ep-modal-overlay" onClick={() => setDeleteConfirm(null)}>
          <div className="ep-modal" style={{ width: "min(420px, 95vw)" }} onClick={(e) => e.stopPropagation()}>
            <div className="ep-modal-header">
              <h2>Delete Plan</h2>
              <button className="ep-btn ep-btn-ghost ep-btn-xs" onClick={() => setDeleteConfirm(null)}>✕</button>
            </div>
            <div className="ep-modal-body">
              <p style={{ color: "var(--ep-text-muted)", fontSize: "0.875rem" }}>
                Delete <strong>{deleteConfirm.name}</strong>? Existing subscriptions will not be affected.
              </p>
            </div>
            <div className="ep-modal-footer">
              <button className="ep-btn ep-btn-ghost ep-btn-sm" onClick={() => setDeleteConfirm(null)}>Cancel</button>
              <button
                className="ep-btn ep-btn-sm"
                style={{ background: "var(--ep-danger)", color: "#fff" }}
                onClick={() => deletePlan(deleteConfirm)}
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

function PlanCard({ plan, onEdit, onDelete }: { plan: Plan; onEdit: () => void; onDelete: () => void }) {
  return (
    <div className="ep-card" style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
      {/* Card header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div>
          <div style={{ fontWeight: 700, fontSize: "1rem" }}>{plan.name}</div>
          {plan.description && (
            <div style={{ fontSize: "0.8rem", color: "var(--ep-text-muted)", marginTop: "0.2rem" }}>
              {plan.description}
            </div>
          )}
        </div>
        <span className={`ep-badge ${plan.status === "active" ? "ep-badge-success" : "ep-badge-neutral"}`}>
          {plan.status}
        </span>
      </div>

      {/* Price */}
      <div style={{ fontSize: "1.5rem", fontWeight: 700, letterSpacing: "-0.03em" }}>
        {plan.price != null ? (
          <>{`$${Number(plan.price).toFixed(2)}`}<span style={{ fontSize: "0.875rem", fontWeight: 400, color: "var(--ep-text-muted)" }}>/mo</span></>
        ) : (
          <span style={{ fontSize: "1rem", color: "var(--ep-text-muted)" }}>Free</span>
        )}
      </div>

      {/* Resource grid */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.5rem" }}>
        <ResourceRow icon="💾" label="Disk"      value={fmtMB(plan.disk_limit)} />
        <ResourceRow icon="📡" label="Bandwidth" value={fmtMB(plan.bandwidth_limit)} />
        <ResourceRow icon="🌐" label="Domains"   value={String(plan.domain_limit)} />
        <ResourceRow icon="🔗" label="Subdomains" value={String(plan.subdomain_limit ?? 0)} />
        <ResourceRow icon="🗄️" label="Databases" value={String(plan.database_limit)} />
        <ResourceRow icon="📁" label="FTP"       value={String(plan.ftp_accounts_limit)} />
        {plan.ram_limit != null && (
          <ResourceRow icon="⚡" label="RAM" value={fmtMB(plan.ram_limit)} />
        )}
      </div>

      {/* Actions */}
      <div style={{ display: "flex", gap: "0.5rem", marginTop: "auto", paddingTop: "0.5rem", borderTop: "1px solid var(--ep-border)" }}>
        <button className="ep-btn ep-btn-ghost ep-btn-xs" style={{ flex: 1 }} onClick={onEdit}>
          Edit
        </button>
        <button
          className="ep-btn ep-btn-ghost ep-btn-xs"
          style={{ color: "var(--ep-danger)" }}
          onClick={onDelete}
        >
          Delete
        </button>
      </div>
    </div>
  );
}

function ResourceRow({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: "0.4rem", fontSize: "0.8125rem" }}>
      <span style={{ fontSize: "0.875rem" }}>{icon}</span>
      <span style={{ color: "var(--ep-text-muted)" }}>{label}</span>
      <span style={{ marginLeft: "auto", fontWeight: 600 }}>{value}</span>
    </div>
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtMB(mb: number): string {
  if (mb >= 1024 * 1024) return `${(mb / (1024 * 1024)).toFixed(0)} TB`;
  if (mb >= 1024) return `${(mb / 1024).toFixed(0)} GB`;
  return `${mb} MB`;
}
